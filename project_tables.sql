-- Projects and related tables
CREATE TABLE projects (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '项目ID',
    name VARCHAR(255) NOT NULL COMMENT '项目名称',
    description TEXT COMMENT '项目描述',
    start_date DATE COMMENT '项目开始日期',
    end_date DATE COMMENT '项目结束日期',
    status ENUM('planning', 'ongoing', 'completed', 'suspended') DEFAULT 'planning' COMMENT '项目状态',
    manager_id INT NOT NULL COMMENT '经办人ID',
    contracted_company_id INT COMMENT '甲方公司',
    client_company_id INT COMMENT '乙方公司',
    contract_amount DECIMAL(15,2) COMMENT '项目金额',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (manager_id) REFERENCES users(id),
    FOREIGN KEY (client_company_id) REFERENCES companys(id),
    FOREIGN KEY (contracted_company_id) REFERENCES companys(id)
) COMMENT '项目论坛表';

CREATE TABLE project_members (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '项目成员ID',
    project_id INT COMMENT '项目ID',
    user_id INT COMMENT '用户ID',
    role_id INT COMMENT '角色ID',
    FOREIGN KEY (project_id) REFERENCES projects(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (role_id) REFERENCES roles(id)
) COMMENT '项目成员表';

CREATE TABLE documents (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '文档ID',
    project_id INT COMMENT '项目ID',
    name VARCHAR(255) COMMENT '文档名称',
    file_path VARCHAR(255) COMMENT '文件路径',
    type ENUM('contract', 'invoice', 'task_report', 'technical_disclosure', 'safety_disclosure') COMMENT '文档类型',
    file_type VARCHAR(50) COMMENT '文件类型',
    upload_user_id INT NOT NULL COMMENT '上传用户ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (project_id) REFERENCES projects(id)
) COMMENT '文档表';

-- Tasks and related tables
CREATE TABLE tasks (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '任务ID',
    project_id INT COMMENT '项目ID',
    name VARCHAR(255) COMMENT '任务名称',
    description TEXT COMMENT '任务描述',
    status ENUM('pending', 'in_progress', 'review', 'completed', 'cancelled') DEFAULT 'pending' COMMENT '任务状态',
    approval_flow_id INT COMMENT '审批流程模板ID',
    creator_id INT NOT NULL COMMENT '任务创建人ID',
    assignee_id INT COMMENT '任务执行人ID',
    start_date DATE COMMENT '任务开始日期',
    end_date DATE COMMENT '任务结束日期',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (project_id) REFERENCES projects(id),
    FOREIGN KEY (approval_flow_id) REFERENCES approval_flow_templates(id),
    FOREIGN KEY (creator_id) REFERENCES users(id),
    FOREIGN KEY (assignee_id) REFERENCES users(id)
) COMMENT '任务BBS主贴表';

CREATE TABLE bbs_posts (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '帖子ID',
    task_id INT NOT NULL COMMENT '所属主题ID',
    user_id INT NOT NULL COMMENT '发布用户ID',
    content TEXT NOT NULL COMMENT '帖子内容',
    is_bot_mentioned BOOLEAN DEFAULT FALSE COMMENT '是否@机器人',
    parent_id INT COMMENT '父帖子ID，用于回复',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (task_id) REFERENCES tasks(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (parent_id) REFERENCES bbs_posts(id)
) COMMENT 'BBS帖子表';

-- 添加LLM模型处理相关表
CREATE TABLE llm_messages (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '消息ID',
    post_id INT COMMENT 'BBS帖子ID',
    user_id INT NOT NULL COMMENT '用户ID',
    content TEXT NOT NULL COMMENT '原始消息内容',
    processed_content TEXT COMMENT 'LLM处理后的内容',
    intent_type ENUM('task_application', 'approval_request', 'information_query', 'other') COMMENT '意图类型',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (post_id) REFERENCES bbs_posts(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
) COMMENT 'LLM处理的消息表';

CREATE TABLE task_periods (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '任务周期ID',
    task_id INT COMMENT '任务ID',
    message_id INT NOT NULL COMMENT '关联的LLM消息ID',
    frequency ENUM('daily', 'weekly', 'monthly', 'quarterly', 'yearly') COMMENT '周期频率',
    period_start DATE COMMENT '周期开始日期',
    period_end DATE COMMENT '周期结束日期',
    FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
) COMMENT '任务周期表';

CREATE TABLE task_quantity (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '任务工程量ID',
    message_id INT NOT NULL COMMENT '关联的LLM消息ID',
    task_id INT COMMENT '任务ID',
    quantity DECIMAL(10, 2) COMMENT '工程量',
    unit VARCHAR(50) COMMENT '单位',
    description TEXT COMMENT '描述',
    start_time DATETIME COMMENT '开始时间',
    end_time DATETIME COMMENT '结束时间',
    images JSON COMMENT '工作图片',
    videos JSON COMMENT '工作视频',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
) COMMENT '任务工程量表';

CREATE TABLE task_materials (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '任务材料ID',
    message_id INT NOT NULL COMMENT '关联的LLM消息ID',
    task_id INT COMMENT '任务ID',
    material_name VARCHAR(255) COMMENT '材料名称',
    quantity DECIMAL(10, 2) COMMENT '数量',
    unit VARCHAR(50) COMMENT '单位',
    type ENUM('equipment', 'consumable', 'temporary') COMMENT '材料类型',
    owner ENUM('party_a', 'party_b') COMMENT '材料所有方',
    description TEXT COMMENT '描述',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
) COMMENT '任务材料表';

CREATE TABLE task_tech_disclosure (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '技术交底ID',
    message_id INT NOT NULL COMMENT '关联的LLM消息ID',
    task_id INT COMMENT '任务ID',
    content TEXT COMMENT '内容',
    disclosed_by INT COMMENT '交底人ID',
    disclosed INT COMMENT '被交底人ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
) COMMENT '技术交底表';

CREATE TABLE task_safe_disclosure (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '安全交底ID',
    message_id INT NOT NULL COMMENT '关联的LLM消息ID',
    task_id INT COMMENT '任务ID',
    content TEXT COMMENT '内容',
    disclosed_by INT COMMENT '交底人ID',
    disclosed INT COMMENT '被交底人ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
) COMMENT '安全交底表';

-- Approval flows and related tables
CREATE TABLE approval_flows (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '审批流程ID',
    name VARCHAR(255) COMMENT '审批流程名称',
    html_template TEXT COMMENT 'HTML模板',
    form_elements JSON COMMENT '节点包含的表单元素',
    approval_nodes JSON COMMENT '按次序排列的多个审批节点ID',
    type ENUM('start', 'subprocess', 'end') DEFAULT 'start' COMMENT '流程类型',
    approval_type ENUM('single', 'multi_one', 'multi_all') DEFAULT 'single' COMMENT '审批类型',
    approver_type VARCHAR(50) COMMENT '审批人类型',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) COMMENT '审批流程表';

CREATE TABLE approval_flows_inst (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '审批流程实例ID',
    message_id INT NOT NULL COMMENT '关联的LLM消息ID',
    approval_flow_id INT COMMENT '审批流程ID',
    task_id INT COMMENT '任务ID',
    process_status VARCHAR(50) COMMENT '节点过程状态',
    form_element_val JSON COMMENT '节点包含的表单元素值',
    approval_node_inst JSON COMMENT '按次序排列的多个审批节点实例ID',
    task_quantities JSON COMMENT '按次序排列的多个任务工程量ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (approval_flow_id) REFERENCES approval_flows(id),
    FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
) COMMENT '审批流程实例表';

CREATE TABLE approval_nodes (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '审批节点ID',
    approval_flow_id INT COMMENT '审批流程ID',
    node_type VARCHAR(50) COMMENT '节点类型',
    approver_role_id VARCHAR(50) COMMENT '审批人角色',
    form_elements JSON COMMENT '节点包含的表单元素',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (approval_flow_id) REFERENCES approval_flows(id),
    FOREIGN KEY (approver_role_id) REFERENCES roles(id)
) COMMENT '审批节点表';

CREATE TABLE approval_node_inst (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '审批节点实例ID',
    message_id INT NOT NULL COMMENT '关联的LLM消息ID',
    approval_flow_inst_id INT COMMENT '审批流程实例ID',
    approval_node_id INT COMMENT '审批节点ID',
    approver JSON COMMENT '审批人id',
    form_element_val JSON COMMENT '节点包含的表单元素值',
    process_status VARCHAR(50) COMMENT '节点过程状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (approval_flow_inst_id) REFERENCES approval_flows_inst(id),
    FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    FOREIGN KEY (approval_node_id) REFERENCES approval_nodes(id)
) COMMENT '审批节点实例表';

CREATE TABLE form_elements (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '表单元素ID',
    approval_flow_id INT COMMENT '审批流程ID',
    approval_node_id INT COMMENT '审批节点ID',
    element_type VARCHAR(50) COMMENT '元素类型',
    label VARCHAR(255) COMMENT '标签',
    options TEXT COMMENT '选项',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (approval_flow_id) REFERENCES approval_flows(id),
    FOREIGN KEY (approval_node_id) REFERENCES approval_nodes(id)
) COMMENT '表单元素表';

CREATE TABLE form_element_val (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '表单元素值ID',
    approval_flow_inst_id INT COMMENT '审批流程实例ID',
    form_element_id INT COMMENT '表单元素ID',
    value MEDIUMTEXT COMMENT '值（文字或图片）',
    default_value TEXT COMMENT '默认值',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (approval_flow_inst_id) REFERENCES approval_flows_inst(id),
    FOREIGN KEY (form_element_id) REFERENCES form_elements(id)
) COMMENT '表单元素值表';

-- Users and related tables
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '用户ID',
    openid VARCHAR(128) UNIQUE NOT NULL COMMENT '微信用户的唯一标识',
    nickname VARCHAR(255) NOT NULL COMMENT '用户昵称',
    avatar_url VARCHAR(512) COMMENT '用户头像URL',
    sex ENUM('male', 'female', 'other') COMMENT '性别',
    birthday DATE COMMENT '生日',
    name VARCHAR(255) COMMENT '姓名',
    email VARCHAR(255) UNIQUE COMMENT '邮箱',
    password VARCHAR(255) COMMENT '密码',
    position_id INT COMMENT '职位ID',
    department_id INT COMMENT '部门ID',
    roles JSON COMMENT '按次序排列的多个角色ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (position_id) REFERENCES positions(id),
    FOREIGN KEY (department_id) REFERENCES departments(id)
) COMMENT '用户表';

CREATE TABLE positions (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '职位ID',
    name VARCHAR(255) COMMENT '职位名称',
    supervisor_id INT COMMENT '直属上级ID',
    FOREIGN KEY (supervisor_id) REFERENCES positions(id)
) COMMENT '职位表';

CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '部门ID',
    superdep_id INT COMMENT '上级部门ID',
    FOREIGN KEY (superdep_id) REFERENCES departments(id),
    name VARCHAR(255) COMMENT '部门名称',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) COMMENT '部门表';

CREATE TABLE roles (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '角色ID',
    name VARCHAR(255) COMMENT '角色名称',
    approval_nodes_id INT COMMENT '审批节点ID',
    FOREIGN KEY (approval_nodes_id) REFERENCES approval_nodes(id)
) COMMENT '角色表';

CREATE TABLE companys (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '公司唯一标识',
    name VARCHAR(255) NOT NULL COMMENT '公司名称',
    address VARCHAR(255) COMMENT '公司地址',
    contact_person VARCHAR(255) COMMENT '联系人',
    contact_phone VARCHAR(50) COMMENT '联系电话',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间'
) COMMENT '公司表';