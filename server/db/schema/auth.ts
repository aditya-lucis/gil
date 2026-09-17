import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  date,
  timestamp,
  uniqueIndex,
  index,
  check,
  primaryKey
} from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'
import { tenants, companies, branches, departments } from './org'

// ==============================================================================
// 1. USERS (System User Accounts — Authentication Identity)
// Authoritative identity master storing login credentials and authentication state
// ==============================================================================
export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    email: varchar('email', { length: 255 }).notNull(),
    passwordHash: varchar('password_hash', { length: 255 }).notNull(), // Argon2id hash
    name: varchar('name', { length: 255 }).notNull(),
    primaryDepartmentId: uuid('primary_department_id').references(
      () => departments.id,
      { onDelete: 'set null' }
    ),
    primaryCompanyId: uuid('primary_company_id').references(
      () => companies.id,
      { onDelete: 'set null' }
    ),
    isActive: boolean('is_active').notNull().default(true),
    isLocked: boolean('is_locked').notNull().default(false),
    lockedUntil: timestamp('locked_until', { withTimezone: true }),
    failedLoginCount: integer('failed_login_count').notNull().default(0),
    lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
    passwordChangedAt: timestamp('password_changed_at', { withTimezone: true }),
    mfaEnabled: boolean('mfa_enabled').notNull().default(false),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    deletedBy: uuid('deleted_by')
  },
  (table) => [
    check('chk_users_failed_login_count', sql`${table.failedLoginCount} >= 0`),
    uniqueIndex('uq_users_email').on(table.email),
    index('idx_users_tenant').on(table.tenantId),
    index('idx_users_primary_dept').on(table.primaryDepartmentId),
    index('idx_users_primary_company').on(table.primaryCompanyId),
    index('idx_users_active')
      .on(table.tenantId, table.isActive)
      .where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 2. ROLES (Role Definitions — Collection of Permissions)
// Named collections of atomic permissions (e.g. 'super_admin', 'finance_manager')
// ==============================================================================
export const roles = pgTable(
  'roles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id').references(() => tenants.id, {
      onDelete: 'restrict'
    }), // NULL = system role available across all tenants
    code: varchar('code', { length: 32 }).notNull().unique(),
    name: varchar('name', { length: 255 }).notNull(),
    description: text('description'),
    isSystem: boolean('is_system').notNull().default(false), // System roles cannot be deleted
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow()
  },
  (table) => [
    index('idx_roles_tenant').on(table.tenantId),
    index('idx_roles_active').on(table.isActive)
  ]
)

// ==============================================================================
// 3. PERMISSIONS (Atomic Permission Entries — module.action)
// Granular action rights defining authorization boundaries across modules
// ==============================================================================
export const permissions = pgTable(
  'permissions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    code: varchar('code', { length: 128 }).notNull().unique(), // e.g. 'budget.create', 'journal.post'
    module: varchar('module', { length: 64 }).notNull(), // e.g. 'budget', 'journal', 'period'
    action: varchar('action', { length: 64 }).notNull(), // e.g. 'create', 'approve', 'post'
    description: text('description'),
    isSensitive: boolean('is_sensitive').notNull().default(false) // Sensitive actions require elevated audit logging
  },
  (table) => [
    index('idx_permissions_module').on(table.module)
  ]
)

// ==============================================================================
// 4. ROLE_PERMISSIONS (Many-to-Many Junction: Role ↔ Permission)
// Grants specific permissions to roles with cascading deletes on role/permission removal
// ==============================================================================
export const rolePermissions = pgTable(
  'role_permissions',
  {
    roleId: uuid('role_id')
      .notNull()
      .references(() => roles.id, { onDelete: 'cascade' }),
    permissionId: uuid('permission_id')
      .notNull()
      .references(() => permissions.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdBy: uuid('created_by')
  },
  (table) => [
    primaryKey({ columns: [table.roleId, table.permissionId] }),
    index('idx_role_permissions_perm').on(table.permissionId)
  ]
)

// ==============================================================================
// 5. USER_ROLES (Many-to-Many Junction: User ↔ Role with Scope)
// Assigns roles to users with optional department, branch, or company scoping
// ==============================================================================
export const userRoles = pgTable(
  'user_roles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    roleId: uuid('role_id')
      .notNull()
      .references(() => roles.id, { onDelete: 'restrict' }),
    departmentScopeId: uuid('department_scope_id').references(
      () => departments.id,
      { onDelete: 'restrict' }
    ), // NULL = all departments within user scope
    branchScopeId: uuid('branch_scope_id').references(() => branches.id, {
      onDelete: 'restrict'
    }), // NULL = all branches within user scope
    companyScopeId: uuid('company_scope_id').references(() => companies.id, {
      onDelete: 'restrict'
    }), // NULL = all companies within user scope
    validFrom: date('valid_from'),
    validTo: date('valid_to'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdBy: uuid('created_by')
  },
  (table) => [
    check(
      'chk_user_roles_valid_range',
      sql`${table.validTo} IS NULL OR ${table.validFrom} IS NULL OR ${table.validTo} >= ${table.validFrom}`
    ),
    index('idx_user_roles_user').on(table.userId),
    index('idx_user_roles_role').on(table.roleId),
    index('idx_user_roles_dept_scope').on(
      table.userId,
      table.departmentScopeId
    ),
    index('idx_user_roles_company_scope').on(
      table.userId,
      table.companyScopeId
    )
  ]
)
