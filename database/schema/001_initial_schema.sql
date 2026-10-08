-- IP_ADMIN_V2
-- Initial relational model draft.
-- Target: MariaDB / InnoDB.
-- This file is design-only; it must not be executed in production yet.

CREATE TABLE IF NOT EXISTS node_groups (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    group_key VARCHAR(64) NOT NULL,
    display_name VARCHAR(128) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_node_groups_key (group_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS nodes (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    node_name VARCHAR(128) NOT NULL,
    hostname VARCHAR(255) NULL,
    node_category VARCHAR(32) NOT NULL DEFAULT 'DIRECT',
    management_mode VARCHAR(16) NOT NULL DEFAULT 'LEGACY',
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    agent_version VARCHAR(64) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_nodes_name (node_name),
    KEY idx_nodes_mode (management_mode),
    KEY idx_nodes_category (node_category),
    CONSTRAINT ck_nodes_mode
        CHECK (management_mode IN ('LEGACY','OBSERVE','HYBRID','V2'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS node_group_members (
    group_id BIGINT UNSIGNED NOT NULL,
    node_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (group_id, node_id),
    CONSTRAINT fk_ngm_group
        FOREIGN KEY (group_id) REFERENCES node_groups(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ngm_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS firewall_profiles (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    profile_key VARCHAR(64) NOT NULL,
    display_name VARCHAR(128) NOT NULL,
    version INT UNSIGNED NOT NULL DEFAULT 1,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_firewall_profiles_key_version (profile_key, version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS firewall_profile_rules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    profile_id BIGINT UNSIGNED NOT NULL,
    priority INT UNSIGNED NOT NULL,
    protocol VARCHAR(8) NOT NULL,
    destination_ports VARCHAR(255) NOT NULL,
    action VARCHAR(16) NOT NULL DEFAULT 'ACCEPT',
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_profile_rule_priority (profile_id, priority),
    CONSTRAINT fk_profile_rules_profile
        FOREIGN KEY (profile_id) REFERENCES firewall_profiles(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_profile_rule_protocol
        CHECK (protocol IN ('tcp','udp','all')),
    CONSTRAINT ck_profile_rule_action
        CHECK (action IN ('ACCEPT','DROP','REJECT'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS access_requests (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    request_uuid CHAR(36) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    target_key VARCHAR(128) NOT NULL,
    target_type VARCHAR(16) NOT NULL DEFAULT 'NODE',
    requester VARCHAR(128) NULL,
    requested_by VARCHAR(128) NULL,
    reason TEXT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    approved_at DATETIME(6) NULL,
    rejected_at DATETIME(6) NULL,
    revoked_at DATETIME(6) NULL,
    expires_at DATETIME(6) NULL,
    expiration_started_at DATETIME(6) NULL,
    expired_at DATETIME(6) NULL,
    rejected_by VARCHAR(128) NULL,
    firewall_result VARCHAR(64) NULL,
    error_message TEXT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_access_requests_uuid (request_uuid),
    KEY idx_access_requests_ip (ip_address),
    KEY idx_access_requests_target (target_key),
    KEY idx_access_requests_status (status),
    KEY idx_access_requests_expires (expires_at),
    CONSTRAINT ck_access_request_target_type
        CHECK (target_type IN ('NODE','GROUP')),
    CONSTRAINT ck_access_request_status
        CHECK (status IN (
            'PENDING','RECEIVED','APPROVED','APPLYING','ACTIVE',
            'REJECTED','REVOKING','REVOKED','EXPIRING',
            'EXPIRED','ERROR'
        ))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS access_request_targets (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    request_id BIGINT UNSIGNED NOT NULL,
    node_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
    action VARCHAR(8) NOT NULL DEFAULT 'ADD',
    firewall_result VARCHAR(64) NULL,
    error_message TEXT NULL,
    delivered_at DATETIME(6) NULL,
    completed_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_request_target_node (request_id, node_id),
    KEY idx_request_targets_node_status (node_id, status),
    CONSTRAINT fk_request_targets_request
        FOREIGN KEY (request_id) REFERENCES access_requests(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_request_targets_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_request_target_status
        CHECK (status IN ('PENDING','RECEIVED','COMPLETED','ERROR')),
    CONSTRAINT ck_request_target_action
        CHECK (action IN ('ADD','REMOVE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS desired_access (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    node_id BIGINT UNSIGNED NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    profile_id BIGINT UNSIGNED NOT NULL,
    request_target_id BIGINT UNSIGNED NULL,
    source VARCHAR(32) NOT NULL DEFAULT 'V2',
    desired_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    valid_from DATETIME(6) NULL,
    expires_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_desired_access_node_ip (node_id, ip_address),
    KEY idx_desired_access_state (desired_state),
    KEY idx_desired_access_expiry (expires_at),
    KEY idx_desired_access_request_target (request_target_id),
    CONSTRAINT fk_desired_access_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_desired_access_profile
        FOREIGN KEY (profile_id) REFERENCES firewall_profiles(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_desired_access_request_target
        FOREIGN KEY (request_target_id) REFERENCES access_request_targets(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT ck_desired_access_state
        CHECK (desired_state IN ('ACTIVE','REVOKED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS node_actions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    request_target_id BIGINT UNSIGNED NOT NULL,
    node_id BIGINT UNSIGNED NOT NULL,
    action VARCHAR(8) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
    requester VARCHAR(128) NULL,
    delivered_at DATETIME(6) NULL,
    completed_at DATETIME(6) NULL,
    result VARCHAR(64) NULL,
    error_message TEXT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_node_actions_queue (node_id, status, id),
    KEY idx_node_actions_request (request_target_id),
    CONSTRAINT fk_node_actions_target
        FOREIGN KEY (request_target_id) REFERENCES access_request_targets(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_node_actions_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_node_action_action
        CHECK (action IN ('ADD','REMOVE')),
    CONSTRAINT ck_node_action_status
        CHECK (status IN ('PENDING','RECEIVED','COMPLETED','ERROR'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS node_health (
    node_id BIGINT UNSIGNED NOT NULL,
    last_seen DATETIME(6) NULL,
    desired_count INT UNSIGNED NOT NULL DEFAULT 0,
    desired_hash CHAR(64) NULL,
    applied_count INT UNSIGNED NOT NULL DEFAULT 0,
    applied_hash CHAR(64) NULL,
    persisted_count INT UNSIGNED NOT NULL DEFAULT 0,
    persisted_hash CHAR(64) NULL,
    rule_count INT UNSIGNED NOT NULL DEFAULT 0,
    jump_count INT UNSIGNED NOT NULL DEFAULT 0,
    agent_sha CHAR(64) NULL,
    helper_sha CHAR(64) NULL,
    agent_version VARCHAR(64) NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (node_id),
    CONSTRAINT fk_node_health_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS node_health_state (
    node_id BIGINT UNSIGNED NOT NULL,
    state VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN',
    reason VARCHAR(64) NULL,
    state_since DATETIME(6) NULL,
    last_reconcile_at DATETIME(6) NULL,
    last_error_code VARCHAR(64) NULL,
    last_error_message TEXT NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (node_id),
    CONSTRAINT fk_node_health_state_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_node_health_state
        CHECK (state IN ('UNKNOWN','SYNCED','DRIFT','STALE','ERROR'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS node_health_events (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    node_id BIGINT UNSIGNED NOT NULL,
    previous_state VARCHAR(16) NULL,
    new_state VARCHAR(16) NOT NULL,
    reason VARCHAR(64) NULL,
    details TEXT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_health_events_node_time (node_id, created_at),
    CONSTRAINT fk_health_events_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS node_reconcile_runs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    node_id BIGINT UNSIGNED NOT NULL,
    started_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    finished_at DATETIME(6) NULL,
    result VARCHAR(16) NOT NULL DEFAULT 'RUNNING',
    desired_hash CHAR(64) NULL,
    applied_before_hash CHAR(64) NULL,
    applied_after_hash CHAR(64) NULL,
    persisted_hash CHAR(64) NULL,
    error_code VARCHAR(64) NULL,
    error_message TEXT NULL,
    agent_version VARCHAR(64) NULL,
    PRIMARY KEY (id),
    KEY idx_reconcile_node_time (node_id, started_at),
    CONSTRAINT fk_reconcile_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_reconcile_result
        CHECK (result IN ('RUNNING','SYNCED','CHANGED','ERROR','ROLLED_BACK'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ivr_inventory_state (
    node_id BIGINT UNSIGNED NOT NULL,
    last_seen DATETIME(6) NULL,
    inventory_count INT UNSIGNED NOT NULL DEFAULT 0,
    inventory_hash CHAR(64) NULL,
    exporter_version VARCHAR(64) NULL,
    source VARCHAR(128) NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (node_id),
    CONSTRAINT fk_ivr_inventory_state_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ivr_rules_inventory (
    node_id BIGINT UNSIGNED NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    last_seen DATETIME(6) NOT NULL,
    source VARCHAR(128) NULL,
    PRIMARY KEY (node_id, ip_address),
    KEY idx_ivr_inventory_ip (ip_address),
    CONSTRAINT fk_ivr_rules_inventory_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_events (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    event_type VARCHAR(64) NOT NULL,
    actor VARCHAR(128) NULL,
    node_id BIGINT UNSIGNED NULL,
    request_id BIGINT UNSIGNED NULL,
    request_target_id BIGINT UNSIGNED NULL,
    ip_address VARCHAR(45) NULL,
    message TEXT NULL,
    metadata LONGTEXT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_audit_created (created_at),
    KEY idx_audit_node (node_id, created_at),
    KEY idx_audit_request (request_id, created_at),
    CONSTRAINT fk_audit_node
        FOREIGN KEY (node_id) REFERENCES nodes(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_audit_request
        FOREIGN KEY (request_id) REFERENCES access_requests(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_audit_request_target
        FOREIGN KEY (request_target_id) REFERENCES access_request_targets(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
