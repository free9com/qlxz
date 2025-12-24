-- PostgreSQL compatible schema for Supabase

-- Create ENUM types for PostgreSQL
CREATE TYPE project_status AS ENUM ('planning', 'ongoing', 'completed', 'suspended');
CREATE TYPE document_type AS ENUM ('contract', 'invoice', 'task_report', 'technical_disclosure', 'safety_disclosure');
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'review', 'completed', 'cancelled');
CREATE TYPE approval_type AS ENUM ('start', 'subprocess', 'end');
CREATE TYPE approval_flow_type AS ENUM ('single', 'multi_one', 'multi_all');
CREATE TYPE task_frequency AS ENUM ('daily', 'weekly', 'monthly', 'quarterly', 'yearly');
CREATE TYPE material_type AS ENUM ('equipment', 'consumable', 'temporary');
CREATE TYPE material_owner AS ENUM ('party_a', 'party_b');
CREATE TYPE intent_type AS ENUM ('task_application', 'approval_request', 'information_query', 'other');
CREATE TYPE user_sex AS ENUM ('male', 'female', 'other');

-- Projects and related tables
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status project_status DEFAULT 'planning',
    manager_id INT NOT NULL,
    contracted_company_id INT,
    client_company_id INT,
    contract_amount DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_projects_manager FOREIGN KEY (manager_id) REFERENCES users(id),
    CONSTRAINT fk_projects_client_company FOREIGN KEY (client_company_id) REFERENCES companys(id),
    CONSTRAINT fk_projects_contracted_company FOREIGN KEY (contracted_company_id) REFERENCES companys(id)
);

COMMENT ON TABLE projects IS '项目论坛表';
COMMENT ON COLUMN projects.id IS '项目ID';
COMMENT ON COLUMN projects.name IS '项目名称';
COMMENT ON COLUMN projects.description IS '项目描述';
COMMENT ON COLUMN projects.start_date IS '项目开始日期';
COMMENT ON COLUMN projects.end_date IS '项目结束日期';
COMMENT ON COLUMN projects.status IS '项目状态';
COMMENT ON COLUMN projects.manager_id IS '经办人ID';
COMMENT ON COLUMN projects.contracted_company_id IS '甲方公司';
COMMENT ON COLUMN projects.client_company_id IS '乙方公司';
COMMENT ON COLUMN projects.contract_amount IS '项目金额';
COMMENT ON COLUMN projects.created_at IS '创建时间';
COMMENT ON COLUMN projects.updated_at IS '更新时间';

CREATE TABLE project_members (
    id SERIAL PRIMARY KEY,
    project_id INT,
    user_id INT,
    role_id INT,
    CONSTRAINT fk_project_members_project FOREIGN KEY (project_id) REFERENCES projects(id),
    CONSTRAINT fk_project_members_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_project_members_role FOREIGN KEY (role_id) REFERENCES roles(id)
);

COMMENT ON TABLE project_members IS '项目成员表';
COMMENT ON COLUMN project_members.id IS '项目成员ID';
COMMENT ON COLUMN project_members.project_id IS '项目ID';
COMMENT ON COLUMN project_members.user_id IS '用户ID';
COMMENT ON COLUMN project_members.role_id IS '角色ID';

CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    project_id INT,
    name VARCHAR(255),
    file_path VARCHAR(255),
    type document_type,
    file_type VARCHAR(50),
    upload_user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_documents_project FOREIGN KEY (project_id) REFERENCES projects(id)
);

COMMENT ON TABLE documents IS '文档表';
COMMENT ON COLUMN documents.id IS '文档ID';
COMMENT ON COLUMN documents.project_id IS '项目ID';
COMMENT ON COLUMN documents.name IS '文档名称';
COMMENT ON COLUMN documents.file_path IS '文件路径';
COMMENT ON COLUMN documents.type IS '文档类型';
COMMENT ON COLUMN documents.file_type IS '文件类型';
COMMENT ON COLUMN documents.upload_user_id IS '上传用户ID';
COMMENT ON COLUMN documents.created_at IS '创建时间';

-- Tasks and related tables
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    project_id INT,
    name VARCHAR(255),
    description TEXT,
    status task_status DEFAULT 'pending',
    approval_flow_id INT,
    creator_id INT NOT NULL,
    assignee_id INT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tasks_project FOREIGN KEY (project_id) REFERENCES projects(id),
    CONSTRAINT fk_tasks_approval_flow FOREIGN KEY (approval_flow_id) REFERENCES approval_flow_templates(id),
    CONSTRAINT fk_tasks_creator FOREIGN KEY (creator_id) REFERENCES users(id),
    CONSTRAINT fk_tasks_assignee FOREIGN KEY (assignee_id) REFERENCES users(id)
);

COMMENT ON TABLE tasks IS '任务BBS主贴表';
COMMENT ON COLUMN tasks.id IS '任务ID';
COMMENT ON COLUMN tasks.project_id IS '项目ID';
COMMENT ON COLUMN tasks.name IS '任务名称';
COMMENT ON COLUMN tasks.description IS '任务描述';
COMMENT ON COLUMN tasks.status IS '任务状态';
COMMENT ON COLUMN tasks.approval_flow_id IS '审批流程模板ID';
COMMENT ON COLUMN tasks.creator_id IS '任务创建人ID';
COMMENT ON COLUMN tasks.assignee_id IS '任务执行人ID';
COMMENT ON COLUMN tasks.start_date IS '任务开始日期';
COMMENT ON COLUMN tasks.end_date IS '任务结束日期';
COMMENT ON COLUMN tasks.created_at IS '创建时间';
COMMENT ON COLUMN tasks.updated_at IS '更新时间';

CREATE TABLE bbs_posts (
    id SERIAL PRIMARY KEY,
    task_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    is_bot_mentioned BOOLEAN DEFAULT FALSE,
    parent_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bbs_posts_task FOREIGN KEY (task_id) REFERENCES tasks(id),
    CONSTRAINT fk_bbs_posts_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_bbs_posts_parent FOREIGN KEY (parent_id) REFERENCES bbs_posts(id)
);

COMMENT ON TABLE bbs_posts IS 'BBS帖子表';
COMMENT ON COLUMN bbs_posts.id IS '帖子ID';
COMMENT ON COLUMN bbs_posts.task_id IS '所属主题ID';
COMMENT ON COLUMN bbs_posts.user_id IS '发布用户ID';
COMMENT ON COLUMN bbs_posts.content IS '帖子内容';
COMMENT ON COLUMN bbs_posts.is_bot_mentioned IS '是否@机器人';
COMMENT ON COLUMN bbs_posts.parent_id IS '父帖子ID，用于回复';
COMMENT ON COLUMN bbs_posts.created_at IS '创建时间';
COMMENT ON COLUMN bbs_posts.updated_at IS '更新时间';

-- 添加LLM模型处理相关表
CREATE TABLE llm_messages (
    id SERIAL PRIMARY KEY,
    post_id INT,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    processed_content TEXT,
    intent_type intent_type,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_llm_messages_post FOREIGN KEY (post_id) REFERENCES bbs_posts(id),
    CONSTRAINT fk_llm_messages_user FOREIGN KEY (user_id) REFERENCES users(id)
);

COMMENT ON TABLE llm_messages IS 'LLM处理的消息表';
COMMENT ON COLUMN llm_messages.id IS '消息ID';
COMMENT ON COLUMN llm_messages.post_id IS 'BBS帖子ID';
COMMENT ON COLUMN llm_messages.user_id IS '用户ID';
COMMENT ON COLUMN llm_messages.content IS '原始消息内容';
COMMENT ON COLUMN llm_messages.processed_content IS 'LLM处理后的内容';
COMMENT ON COLUMN llm_messages.intent_type IS '意图类型';
COMMENT ON COLUMN llm_messages.created_at IS '创建时间';

CREATE TABLE task_periods (
    id SERIAL PRIMARY KEY,
    task_id INT,
    message_id INT NOT NULL,
    frequency task_frequency,
    period_start DATE,
    period_end DATE,
    CONSTRAINT fk_task_periods_message FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    CONSTRAINT fk_task_periods_task FOREIGN KEY (task_id) REFERENCES tasks(id)
);

COMMENT ON TABLE task_periods IS '任务周期表';
COMMENT ON COLUMN task_periods.id IS '任务周期ID';
COMMENT ON COLUMN task_periods.task_id IS '任务ID';
COMMENT ON COLUMN task_periods.message_id IS '关联的LLM消息ID';
COMMENT ON COLUMN task_periods.frequency IS '周期频率';
COMMENT ON COLUMN task_periods.period_start IS '周期开始日期';
COMMENT ON COLUMN task_periods.period_end IS '周期结束日期';

CREATE TABLE task_quantity (
    id SERIAL PRIMARY KEY,
    message_id INT NOT NULL,
    task_id INT,
    quantity DECIMAL(10, 2),
    unit VARCHAR(50),
    description TEXT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    images JSON,
    videos JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_task_quantity_message FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    CONSTRAINT fk_task_quantity_task FOREIGN KEY (task_id) REFERENCES tasks(id)
);

COMMENT ON TABLE task_quantity IS '任务工程量表';
COMMENT ON COLUMN task_quantity.id IS '任务工程量ID';
COMMENT ON COLUMN task_quantity.message_id IS '关联的LLM消息ID';
COMMENT ON COLUMN task_quantity.task_id IS '任务ID';
COMMENT ON COLUMN task_quantity.quantity IS '工程量';
COMMENT ON COLUMN task_quantity.unit IS '单位';
COMMENT ON COLUMN task_quantity.description IS '描述';
COMMENT ON COLUMN task_quantity.start_time IS '开始时间';
COMMENT ON COLUMN task_quantity.end_time IS '结束时间';
COMMENT ON COLUMN task_quantity.images IS '工作图片';
COMMENT ON COLUMN task_quantity.videos IS '工作视频';
COMMENT ON COLUMN task_quantity.created_at IS '创建时间';

CREATE TABLE task_materials (
    id SERIAL PRIMARY KEY,
    message_id INT NOT NULL,
    task_id INT,
    material_name VARCHAR(255),
    quantity DECIMAL(10, 2),
    unit VARCHAR(50),
    type material_type,
    owner material_owner,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_task_materials_message FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    CONSTRAINT fk_task_materials_task FOREIGN KEY (task_id) REFERENCES tasks(id)
);

COMMENT ON TABLE task_materials IS '任务材料表';
COMMENT ON COLUMN task_materials.id IS '任务材料ID';
COMMENT ON COLUMN task_materials.message_id IS '关联的LLM消息ID';
COMMENT ON COLUMN task_materials.task_id IS '任务ID';
COMMENT ON COLUMN task_materials.material_name IS '材料名称';
COMMENT ON COLUMN task_materials.quantity IS '数量';
COMMENT ON COLUMN task_materials.unit IS '单位';
COMMENT ON COLUMN task_materials.type IS '材料类型';
COMMENT ON COLUMN task_materials.owner IS '材料所有方';
COMMENT ON COLUMN task_materials.description IS '描述';
COMMENT ON COLUMN task_materials.created_at IS '创建时间';

CREATE TABLE task_tech_disclosure (
    id SERIAL PRIMARY KEY,
    message_id INT NOT NULL,
    task_id INT,
    content TEXT,
    disclosed_by INT,
    disclosed INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_task_tech_disclosure_message FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    CONSTRAINT fk_task_tech_disclosure_task FOREIGN KEY (task_id) REFERENCES tasks(id)
);

COMMENT ON TABLE task_tech_disclosure IS '技术交底表';
COMMENT ON COLUMN task_tech_disclosure.id IS '技术交底ID';
COMMENT ON COLUMN task_tech_disclosure.message_id IS '关联的LLM消息ID';
COMMENT ON COLUMN task_tech_disclosure.task_id IS '任务ID';
COMMENT ON COLUMN task_tech_disclosure.content IS '内容';
COMMENT ON COLUMN task_tech_disclosure.disclosed_by IS '交底人ID';
COMMENT ON COLUMN task_tech_disclosure.disclosed IS '被交底人ID';
COMMENT ON COLUMN task_tech_disclosure.created_at IS '创建时间';

CREATE TABLE task_safe_disclosure (
    id SERIAL PRIMARY KEY,
    message_id INT NOT NULL,
    task_id INT,
    content TEXT,
    disclosed_by INT,
    disclosed INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_task_safe_disclosure_message FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    CONSTRAINT fk_task_safe_disclosure_task FOREIGN KEY (task_id) REFERENCES tasks(id)
);

COMMENT ON TABLE task_safe_disclosure IS '安全交底表';
COMMENT ON COLUMN task_safe_disclosure.id IS '安全交底ID';
COMMENT ON COLUMN task_safe_disclosure.message_id IS '关联的LLM消息ID';
COMMENT ON COLUMN task_safe_disclosure.task_id IS '任务ID';
COMMENT ON COLUMN task_safe_disclosure.content IS '内容';
COMMENT ON COLUMN task_safe_disclosure.disclosed_by IS '交底人ID';
COMMENT ON COLUMN task_safe_disclosure.disclosed IS '被交底人ID';
COMMENT ON COLUMN task_safe_disclosure.created_at IS '创建时间';

-- Approval flows and related tables
CREATE TABLE approval_flows (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    html_template TEXT,
    form_elements JSON,
    approval_nodes JSON,
    type approval_type DEFAULT 'start',
    approval_type approval_flow_type DEFAULT 'single',
    approver_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE approval_flows IS '审批流程表';
COMMENT ON COLUMN approval_flows.id IS '审批流程ID';
COMMENT ON COLUMN approval_flows.name IS '审批流程名称';
COMMENT ON COLUMN approval_flows.html_template IS 'HTML模板';
COMMENT ON COLUMN approval_flows.form_elements IS '节点包含的表单元素';
COMMENT ON COLUMN approval_flows.approval_nodes IS '按次序排列的多个审批节点ID';
COMMENT ON COLUMN approval_flows.type IS '流程类型';
COMMENT ON COLUMN approval_flows.approval_type IS '审批类型';
COMMENT ON COLUMN approval_flows.approver_type IS '审批人类型';
COMMENT ON COLUMN approval_flows.created_at IS '创建时间';

CREATE TABLE approval_flows_inst (
    id SERIAL PRIMARY KEY,
    message_id INT NOT NULL,
    approval_flow_id INT,
    task_id INT,
    process_status VARCHAR(50),
    form_element_val JSON,
    approval_node_inst JSON,
    task_quantities JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_approval_flows_inst_flow FOREIGN KEY (approval_flow_id) REFERENCES approval_flows(id),
    CONSTRAINT fk_approval_flows_inst_message FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    CONSTRAINT fk_approval_flows_inst_task FOREIGN KEY (task_id) REFERENCES tasks(id)
);

COMMENT ON TABLE approval_flows_inst IS '审批流程实例表';
COMMENT ON COLUMN approval_flows_inst.id IS '审批流程实例ID';
COMMENT ON COLUMN approval_flows_inst.message_id IS '关联的LLM消息ID';
COMMENT ON COLUMN approval_flows_inst.approval_flow_id IS '审批流程ID';
COMMENT ON COLUMN approval_flows_inst.task_id IS '任务ID';
COMMENT ON COLUMN approval_flows_inst.process_status IS '节点过程状态';
COMMENT ON COLUMN approval_flows_inst.form_element_val IS '节点包含的表单元素值';
COMMENT ON COLUMN approval_flows_inst.approval_node_inst IS '按次序排列的多个审批节点实例ID';
COMMENT ON COLUMN approval_flows_inst.task_quantities IS '按次序排列的多个任务工程量ID';
COMMENT ON COLUMN approval_flows_inst.created_at IS '创建时间';

CREATE TABLE approval_nodes (
    id SERIAL PRIMARY KEY,
    approval_flow_id INT,
    node_type VARCHAR(50),
    approver_role_id VARCHAR(50),
    form_elements JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_approval_nodes_flow FOREIGN KEY (approval_flow_id) REFERENCES approval_flows(id),
    CONSTRAINT fk_approval_nodes_role FOREIGN KEY (approver_role_id) REFERENCES roles(id)
);

COMMENT ON TABLE approval_nodes IS '审批节点表';
COMMENT ON COLUMN approval_nodes.id IS '审批节点ID';
COMMENT ON COLUMN approval_nodes.approval_flow_id IS '审批流程ID';
COMMENT ON COLUMN approval_nodes.node_type IS '节点类型';
COMMENT ON COLUMN approval_nodes.approver_role_id IS '审批人角色';
COMMENT ON COLUMN approval_nodes.form_elements IS '节点包含的表单元素';
COMMENT ON COLUMN approval_nodes.created_at IS '创建时间';

CREATE TABLE approval_node_inst (
    id SERIAL PRIMARY KEY,
    message_id INT NOT NULL,
    approval_flow_inst_id INT,
    approval_node_id INT,
    approver JSON,
    form_element_val JSON,
    process_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_approval_node_inst_flow_inst FOREIGN KEY (approval_flow_inst_id) REFERENCES approval_flows_inst(id),
    CONSTRAINT fk_approval_node_inst_message FOREIGN KEY (message_id) REFERENCES llm_messages(id),
    CONSTRAINT fk_approval_node_inst_node FOREIGN KEY (approval_node_id) REFERENCES approval_nodes(id)
);

COMMENT ON TABLE approval_node_inst IS '审批节点实例表';
COMMENT ON COLUMN approval_node_inst.id IS '审批节点实例ID';
COMMENT ON COLUMN approval_node_inst.message_id IS '关联的LLM消息ID';
COMMENT ON COLUMN approval_node_inst.approval_flow_inst_id IS '审批流程实例ID';
COMMENT ON COLUMN approval_node_inst.approval_node_id IS '审批节点ID';
COMMENT ON COLUMN approval_node_inst.approver IS '审批人id';
COMMENT ON COLUMN approval_node_inst.form_element_val IS '节点包含的表单元素值';
COMMENT ON COLUMN approval_node_inst.process_status IS '节点过程状态';
COMMENT ON COLUMN approval_node_inst.created_at IS '创建时间';

CREATE TABLE form_elements (
    id SERIAL PRIMARY KEY,
    approval_flow_id INT,
    approval_node_id INT,
    element_type VARCHAR(50),
    label VARCHAR(255),
    options TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_form_elements_flow FOREIGN KEY (approval_flow_id) REFERENCES approval_flows(id),
    CONSTRAINT fk_form_elements_node FOREIGN KEY (approval_node_id) REFERENCES approval_nodes(id)
);

COMMENT ON TABLE form_elements IS '表单元素表';
COMMENT ON COLUMN form_elements.id IS '表单元素ID';
COMMENT ON COLUMN form_elements.approval_flow_id IS '审批流程ID';
COMMENT ON COLUMN form_elements.approval_node_id IS '审批节点ID';
COMMENT ON COLUMN form_elements.element_type IS '元素类型';
COMMENT ON COLUMN form_elements.label IS '标签';
COMMENT ON COLUMN form_elements.options IS '选项';
COMMENT ON COLUMN form_elements.created_at IS '创建时间';

CREATE TABLE form_element_val (
    id SERIAL PRIMARY KEY,
    approval_flow_inst_id INT,
    form_element_id INT,
    value TEXT,
    default_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_form_element_val_flow_inst FOREIGN KEY (approval_flow_inst_id) REFERENCES approval_flows_inst(id),
    CONSTRAINT fk_form_element_val_element FOREIGN KEY (form_element_id) REFERENCES form_elements(id)
);

COMMENT ON TABLE form_element_val IS '表单元素值表';
COMMENT ON COLUMN form_element_val.id IS '表单元素值ID';
COMMENT ON COLUMN form_element_val.approval_flow_inst_id IS '审批流程实例ID';
COMMENT ON COLUMN form_element_val.form_element_id IS '表单元素ID';
COMMENT ON COLUMN form_element_val.value IS '值（文字或图片）';
COMMENT ON COLUMN form_element_val.default_value IS '默认值';
COMMENT ON COLUMN form_element_val.created_at IS '创建时间';

-- Users and related tables
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    openid VARCHAR(128) UNIQUE NOT NULL,
    nickname VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(512),
    sex user_sex,
    birthday DATE,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    position_id INT,
    department_id INT,
    roles JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_position FOREIGN KEY (position_id) REFERENCES positions(id),
    CONSTRAINT fk_users_department FOREIGN KEY (department_id) REFERENCES departments(id)
);

COMMENT ON TABLE users IS '用户表';
COMMENT ON COLUMN users.id IS '用户ID';
COMMENT ON COLUMN users.openid IS '微信用户的唯一标识';
COMMENT ON COLUMN users.nickname IS '用户昵称';
COMMENT ON COLUMN users.avatar_url IS '用户头像URL';
COMMENT ON COLUMN users.sex IS '性别';
COMMENT ON COLUMN users.birthday IS '生日';
COMMENT ON COLUMN users.name IS '姓名';
COMMENT ON COLUMN users.email IS '邮箱';
COMMENT ON COLUMN users.password IS '密码';
COMMENT ON COLUMN users.position_id IS '职位ID';
COMMENT ON COLUMN users.department_id IS '部门ID';
COMMENT ON COLUMN users.roles IS '按次序排列的多个角色ID';
COMMENT ON COLUMN users.created_at IS '创建时间';

CREATE TABLE positions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    supervisor_id INT,
    CONSTRAINT fk_positions_supervisor FOREIGN KEY (supervisor_id) REFERENCES positions(id)
);

COMMENT ON TABLE positions IS '职位表';
COMMENT ON COLUMN positions.id IS '职位ID';
COMMENT ON COLUMN positions.name IS '职位名称';
COMMENT ON COLUMN positions.supervisor_id IS '直属上级ID';

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    superdep_id INT,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_departments_superdep FOREIGN KEY (superdep_id) REFERENCES departments(id)
);

COMMENT ON TABLE departments IS '部门表';
COMMENT ON COLUMN departments.id IS '部门ID';
COMMENT ON COLUMN departments.superdep_id IS '上级部门ID';
COMMENT ON COLUMN departments.name IS '部门名称';
COMMENT ON COLUMN departments.created_at IS '创建时间';

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    approval_nodes_id INT,
    CONSTRAINT fk_roles_approval_nodes FOREIGN KEY (approval_nodes_id) REFERENCES approval_nodes(id)
);

COMMENT ON TABLE roles IS '角色表';
COMMENT ON COLUMN roles.id IS '角色ID';
COMMENT ON COLUMN roles.name IS '角色名称';
COMMENT ON COLUMN roles.approval_nodes_id IS '审批节点ID';

CREATE TABLE companys (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    contact_person VARCHAR(255),
    contact_phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE companys IS '公司表';
COMMENT ON COLUMN companys.id IS '公司唯一标识';
COMMENT ON COLUMN companys.name IS '公司名称';
COMMENT ON COLUMN companys.address IS '公司地址';
COMMENT ON COLUMN companys.contact_person IS '联系人';
COMMENT ON COLUMN companys.contact_phone IS '联系电话';
COMMENT ON COLUMN companys.created_at IS '创建时间';
COMMENT ON COLUMN companys.updated_at IS '最后更新时间';