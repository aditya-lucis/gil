import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  numeric,
  date,
  timestamp,
  uniqueIndex,
  index,
  check
} from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'
import {
  currencies,
  tenants,
  companies,
  branches,
  departments
} from './org'
import { users } from './auth'

// ==============================================================================
// 1. ACCOUNT_TYPES (Account Type Master: Asset, Liability, Equity, Revenue, Expense)
// Foundational accounting classifications defining normal balance behavior
// ==============================================================================
export const accountTypes = pgTable(
  'account_types',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    code: varchar('code', { length: 32 }).notNull().unique(), // 'asset', 'liability', 'equity', 'revenue', 'expense'
    name: varchar('name', { length: 100 }).notNull(),
    normalBalance: varchar('normal_balance', { length: 10 })
      .notNull()
      .default('debit'), // 'debit' | 'credit'
    description: text('description'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow()
  },
  (table) => [
    check(
      'chk_account_type_normal_balance',
      sql`${table.normalBalance} IN ('debit', 'credit')`
    )
  ]
)

// ==============================================================================
// 2. ACCOUNT_GROUPS (Account Grouping: Current Assets, Fixed Assets, etc.)
// Intermediate categorization grouping accounts under account types
// ==============================================================================
export const accountGroups = pgTable(
  'account_groups',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    accountTypeId: uuid('account_type_id')
      .notNull()
      .references(() => accountTypes.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull().unique(),
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow()
  },
  (table) => [
    index('idx_account_groups_type').on(table.accountTypeId)
  ]
)

// ==============================================================================
// 3. ACCOUNTS (Chart of Accounts — Hierarchical, Multi-Currency, Department-Scoped)
// Core general ledger chart of accounts adhering to PSAK standards
// ==============================================================================
export const accounts = pgTable(
  'accounts',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id').references(() => companies.id, {
      onDelete: 'restrict'
    }), // NULL = global template COA
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    accountTypeId: uuid('account_type_id')
      .notNull()
      .references(() => accountTypes.id, { onDelete: 'restrict' }),
    accountGroupId: uuid('account_group_id').references(
      () => accountGroups.id,
      { onDelete: 'set null' }
    ),
    parentId: uuid('parent_id').references((): any => accounts.id, {
      onDelete: 'restrict'
    }),
    level: integer('level').notNull().default(0),
    isPostable: boolean('is_postable').notNull().default(true),
    isControlAccount: boolean('is_control_account').notNull().default(false),
    currencyCode: varchar('currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    defaultDepartmentId: uuid('default_department_id').references(
      () => departments.id,
      { onDelete: 'set null' }
    ),
    isSensitive: boolean('is_sensitive').notNull().default(false),
    isActive: boolean('is_active').notNull().default(true),
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
    check('chk_account_level', sql`${table.level} >= 0`),
    uniqueIndex('uq_accounts_tenant_company_code').on(
      table.tenantId,
      table.companyId,
      table.code
    ),
    index('idx_accounts_tenant').on(table.tenantId),
    index('idx_accounts_company_code').on(table.companyId, table.code),
    index('idx_accounts_type').on(table.accountTypeId),
    index('idx_accounts_parent').on(table.parentId),
    index('idx_accounts_active')
      .on(table.tenantId, table.companyId, table.isActive)
      .where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 4. COST_CENTERS (Organizational Units for Cost Tracking)
// Responsibility centers for tracking departmental and operational expenses
// ==============================================================================
export const costCenters = pgTable(
  'cost_centers',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    departmentId: uuid('department_id').references(() => departments.id, {
      onDelete: 'set null'
    }),
    parentId: uuid('parent_id').references((): any => costCenters.id, {
      onDelete: 'restrict'
    }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    description: text('description'),
    isActive: boolean('is_active').notNull().default(true),
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
    uniqueIndex('uq_cost_centers_company_code').on(table.companyId, table.code),
    index('idx_cost_centers_tenant').on(table.tenantId),
    index('idx_cost_centers_company').on(table.companyId),
    index('idx_cost_centers_department').on(table.departmentId)
  ]
)

// ==============================================================================
// 5. PROJECTS (Project Master for Project-Based Accounting)
// Operational and capital projects capturing dedicated revenues and costs
// ==============================================================================
export const projects = pgTable(
  'projects',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    departmentId: uuid('department_id').references(() => departments.id, {
      onDelete: 'set null'
    }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    description: text('description'),
    status: varchar('status', { length: 32 }).notNull().default('active'), // 'active', 'completed', 'on_hold', 'cancelled'
    startDate: date('start_date'),
    endDate: date('end_date'),
    isActive: boolean('is_active').notNull().default(true),
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
    check(
      'chk_project_dates',
      sql`${table.endDate} IS NULL OR ${table.startDate} IS NULL OR ${table.endDate} >= ${table.startDate}`
    ),
    uniqueIndex('uq_projects_company_code').on(table.companyId, table.code),
    index('idx_projects_tenant').on(table.tenantId),
    index('idx_projects_company').on(table.companyId),
    index('idx_projects_department').on(table.departmentId)
  ]
)

// ==============================================================================
// 6. DIMENSIONS (Analytical Dimensions: Region, Sales Channel, Line of Business)
// Flexible segmentation dimensions beyond department, cost center, and project
// ==============================================================================
export const dimensions = pgTable(
  'dimensions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow()
  },
  (table) => [
    uniqueIndex('uq_dimensions_tenant_code').on(table.tenantId, table.code),
    index('idx_dimensions_tenant').on(table.tenantId)
  ]
)

// ==============================================================================
// 7. DIMENSION_MEMBERS (Members of Analytical Dimensions)
// Discrete values/segments defined for each analytical dimension
// ==============================================================================
export const dimensionMembers = pgTable(
  'dimension_members',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    dimensionId: uuid('dimension_id')
      .notNull()
      .references(() => dimensions.id, { onDelete: 'cascade' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow()
  },
  (table) => [
    uniqueIndex('uq_dimension_members_dim_code').on(
      table.dimensionId,
      table.code
    ),
    index('idx_dimension_members_dim').on(table.dimensionId)
  ]
)

// ==============================================================================
// 8. FISCAL_YEARS (Fiscal Year Master per Company)
// Annual accounting calendar boundary controlling fiscal periods and closing
// ==============================================================================
export const fiscalYears = pgTable(
  'fiscal_years',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    name: varchar('name', { length: 32 }).notNull(), // e.g. 'FY2026'
    startDate: date('start_date').notNull(),
    endDate: date('end_date').notNull(),
    status: varchar('status', { length: 16 }).notNull().default('open'), // 'open' | 'closed'
    isAdjustment: boolean('is_adjustment').notNull().default(false)
  },
  (table) => [
    check('chk_fy_status', sql`${table.status} IN ('open', 'closed')`),
    check('chk_fy_dates', sql`${table.endDate} > ${table.startDate}`),
    uniqueIndex('uq_fiscal_years_company_name').on(table.companyId, table.name),
    index('idx_fiscal_years_company').on(table.companyId)
  ]
)

// ==============================================================================
// 9. FISCAL_PERIODS (Accounting Periods within Fiscal Years)
// Monthly and adjustment accounting periods with multi-level close controls
// ==============================================================================
export const fiscalPeriods = pgTable(
  'fiscal_periods',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    fiscalYearId: uuid('fiscal_year_id')
      .notNull()
      .references(() => fiscalYears.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    name: varchar('name', { length: 32 }).notNull(), // e.g. '2026-01'
    periodNumber: integer('period_number').notNull(), // 1 to 13 (13 for year-end audit adjustments)
    startDate: date('start_date').notNull(),
    endDate: date('end_date').notNull(),
    status: varchar('status', { length: 16 }).notNull().default('open'), // 'open' | 'soft_closed' | 'hard_closed' | 'reopened'
    softClosedAt: timestamp('soft_closed_at', { withTimezone: true }),
    softClosedBy: uuid('soft_closed_by').references(() => users.id),
    hardClosedAt: timestamp('hard_closed_at', { withTimezone: true }),
    hardClosedBy: uuid('hard_closed_by').references(() => users.id),
    adjustmentPeriod: boolean('adjustment_period').notNull().default(false)
  },
  (table) => [
    check(
      'chk_fp_period_number',
      sql`${table.periodNumber} BETWEEN 1 AND 13`
    ),
    check('chk_fp_dates', sql`${table.endDate} > ${table.startDate}`),
    check(
      'chk_fp_status',
      sql`${table.status} IN ('open', 'soft_closed', 'hard_closed', 'reopened')`
    ),
    uniqueIndex('uq_fiscal_periods_company_name').on(
      table.companyId,
      table.name
    ),
    index('idx_fiscal_periods_company_start').on(
      table.companyId,
      table.startDate
    ),
    index('idx_fiscal_periods_company_status').on(
      table.companyId,
      table.status
    ),
    index('idx_fiscal_periods_year').on(table.fiscalYearId)
  ]
)

// ==============================================================================
// 10. JOURNAL_SOURCES (Origin of Journal Entries: Manual, AR, AP, Sales, Purchase)
// Identifies originating subsystem or integration for posting traceability
// ==============================================================================
export const journalSources = pgTable(
  'journal_sources',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    code: varchar('code', { length: 32 }).notNull().unique(), // 'manual', 'ar', 'ap', 'sales', 'purchase', 'inventory', 'cash_bank', 'payroll'
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    isActive: boolean('is_active').notNull().default(true)
  }
)

// ==============================================================================
// 11. JOURNAL_CATEGORIES (Journal Classification: Operating, Adjusting, Closing)
// Operational categorization separating standard entries from revaluations & closing
// ==============================================================================
export const journalCategories = pgTable(
  'journal_categories',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    code: varchar('code', { length: 32 }).notNull().unique(), // 'operating', 'adjusting', 'closing', 'reversing'
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    isActive: boolean('is_active').notNull().default(true)
  }
)

// ==============================================================================
// 12. JOURNAL_BATCHES (Batch Grouping for Concurrent Postings)
// Groups journal entries processed together in automated or batch posting operations
// ==============================================================================
export const journalBatches = pgTable(
  'journal_batches',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    batchNumber: varchar('batch_number', { length: 64 }).notNull().unique(),
    description: text('description'),
    status: varchar('status', { length: 16 }).notNull().default('open'), // 'open', 'posted', 'cancelled'
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by')
  },
  (table) => [
    check('chk_batch_status', sql`${table.status} IN ('open', 'posted', 'cancelled')`),
    index('idx_journal_batches_company').on(table.companyId)
  ]
)

// ==============================================================================
// 13. RECURRING_JOURNAL_TEMPLATES (Templates for Automatically Recurring Journals)
// Parameterized journal models for recurring periodic allocations & accruals
// ==============================================================================
export const recurringJournalTemplates = pgTable(
  'recurring_journal_templates',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    frequency: varchar('frequency', { length: 32 }).notNull().default('monthly'), // 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
    description: text('description'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by')
  },
  (table) => [
    uniqueIndex('uq_recurring_templates_company_code').on(
      table.companyId,
      table.code
    ),
    index('idx_recurring_templates_company').on(table.companyId)
  ]
)

// ==============================================================================
// 14. JOURNALS (Journal Entry Header — Double-Entry, Immutable Once Posted)
// Primary general ledger journal header enforcing total debit = total credit
// ==============================================================================
export const journals = pgTable(
  'journals',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    branchId: uuid('branch_id').references(() => branches.id, {
      onDelete: 'set null'
    }),
    journalNumber: varchar('journal_number', { length: 64 }).notNull().unique(),
    sourceId: uuid('source_id')
      .notNull()
      .references(() => journalSources.id, { onDelete: 'restrict' }),
    categoryId: uuid('category_id').references(() => journalCategories.id, {
      onDelete: 'set null'
    }),
    batchId: uuid('batch_id').references(() => journalBatches.id, {
      onDelete: 'set null'
    }),
    periodId: uuid('period_id')
      .notNull()
      .references(() => fiscalPeriods.id, { onDelete: 'restrict' }),
    entryDate: date('entry_date').notNull(),
    description: text('description'),
    status: varchar('status', { length: 16 }).notNull().default('draft'), // 'draft', 'posted', 'reversed', 'cancelled'
    isReversing: boolean('is_reversing').notNull().default(false),
    reversesJournalId: uuid('reverses_journal_id').references(
      (): any => journals.id,
      { onDelete: 'set null' }
    ),
    isRecurring: boolean('is_recurring').notNull().default(false),
    recurringTemplateId: uuid('recurring_template_id').references(
      () => recurringJournalTemplates.id,
      { onDelete: 'set null' }
    ),
    isClosing: boolean('is_closing').notNull().default(false),
    currencyCode: varchar('currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    exchangeRate: numeric('exchange_rate', { precision: 20, scale: 6 })
      .notNull()
      .default('1'),
    totalDebit: numeric('total_debit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    totalCredit: numeric('total_credit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    postedAt: timestamp('posted_at', { withTimezone: true }),
    postedBy: uuid('posted_by').references(() => users.id),
    approvalRequestId: uuid('approval_request_id'), // Polymorphic approval engine link
    isReopenedPeriod: boolean('is_reopened_period').notNull().default(false),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by')
  },
  (table) => [
    check(
      'chk_journal_status',
      sql`${table.status} IN ('draft', 'posted', 'reversed', 'cancelled')`
    ),
    check('chk_journal_exchange_rate', sql`${table.exchangeRate} > 0`),
    check('chk_journal_balanced', sql`${table.totalDebit} = ${table.totalCredit}`),
    index('idx_journals_tenant').on(table.tenantId),
    index('idx_journals_company_period').on(table.companyId, table.periodId),
    index('idx_journals_company_status').on(table.companyId, table.status),
    index('idx_journals_period_status').on(table.periodId, table.status),
    index('idx_journals_entry_date').on(table.entryDate)
  ]
)

// ==============================================================================
// 15. JOURNAL_LINES (Individual Debit/Credit Lines of a Journal Entry)
// Atomic double-entry lines enforcing strictly debit OR credit, never both
// ==============================================================================
export const journalLines = pgTable(
  'journal_lines',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    journalId: uuid('journal_id')
      .notNull()
      .references(() => journals.id, { onDelete: 'cascade' }),
    lineNumber: integer('line_number').notNull(),
    accountId: uuid('account_id')
      .notNull()
      .references(() => accounts.id, { onDelete: 'restrict' }),
    departmentId: uuid('department_id').references(() => departments.id, {
      onDelete: 'set null'
    }),
    costCenterId: uuid('cost_center_id').references(() => costCenters.id, {
      onDelete: 'set null'
    }),
    projectId: uuid('project_id').references(() => projects.id, {
      onDelete: 'set null'
    }),
    dimensionMemberId: uuid('dimension_member_id').references(
      () => dimensionMembers.id,
      { onDelete: 'set null' }
    ),
    debit: numeric('debit', { precision: 18, scale: 2 }).notNull().default('0'),
    credit: numeric('credit', { precision: 18, scale: 2 }).notNull().default('0'),
    debitForeign: numeric('debit_foreign', { precision: 18, scale: 2 }),
    creditForeign: numeric('credit_foreign', { precision: 18, scale: 2 }),
    currencyCode: varchar('currency_code', { length: 3 }).references(
      () => currencies.code
    ),
    exchangeRate: numeric('exchange_rate', { precision: 20, scale: 6 }),
    description: text('description'),
    budgetLineId: uuid('budget_line_id'), // Link to budget line encumbrance/actuals
    sourceDocType: varchar('source_doc_type', { length: 64 }),
    sourceDocId: uuid('source_doc_id'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by')
  },
  (table) => [
    check(
      'chk_debit_or_credit',
      sql`(${table.debit} > 0 AND ${table.credit} = 0) OR (${table.credit} > 0 AND ${table.debit} = 0)`
    ),
    index('idx_journal_lines_journal').on(table.journalId),
    index('idx_journal_lines_account').on(table.accountId),
    index('idx_journal_lines_journal_account').on(
      table.journalId,
      table.accountId
    ),
    index('idx_journal_lines_account_dept').on(
      table.accountId,
      table.departmentId
    ),
    index('idx_journal_lines_cost_center').on(table.costCenterId),
    index('idx_journal_lines_project').on(table.projectId)
  ]
)

// ==============================================================================
// 16. OPENING_BALANCES (Period Opening Balance Snapshots per Account)
// Carried-forward opening debit/credit positions anchoring period GL reporting
// ==============================================================================
export const openingBalances = pgTable(
  'opening_balances',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    accountId: uuid('account_id')
      .notNull()
      .references(() => accounts.id, { onDelete: 'restrict' }),
    fiscalYearId: uuid('fiscal_year_id')
      .notNull()
      .references(() => fiscalYears.id, { onDelete: 'restrict' }),
    balanceDebit: numeric('balance_debit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    balanceCredit: numeric('balance_credit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    currencyCode: varchar('currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow()
  },
  (table) => [
    uniqueIndex('uq_opening_balances_account_year').on(
      table.companyId,
      table.accountId,
      table.fiscalYearId
    ),
    index('idx_opening_balances_company').on(table.companyId),
    index('idx_opening_balances_account').on(table.accountId)
  ]
)

// ==============================================================================
// 17. TRIAL_BALANCE_SNAPSHOTS (Pre-Computed Trial Balance per Period Close)
// Immutable point-in-time trial balance snapshot generated during period close
// ==============================================================================
export const trialBalanceSnapshots = pgTable(
  'trial_balance_snapshots',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    periodId: uuid('period_id')
      .notNull()
      .references(() => fiscalPeriods.id, { onDelete: 'restrict' }),
    accountId: uuid('account_id')
      .notNull()
      .references(() => accounts.id, { onDelete: 'restrict' }),
    openingDebit: numeric('opening_debit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    openingCredit: numeric('opening_credit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    periodDebit: numeric('period_debit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    periodCredit: numeric('period_credit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    closingDebit: numeric('closing_debit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    closingCredit: numeric('closing_credit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow()
  },
  (table) => [
    uniqueIndex('uq_tb_snapshots_period_account').on(
      table.companyId,
      table.periodId,
      table.accountId
    ),
    index('idx_tb_snapshots_period').on(table.periodId),
    index('idx_tb_snapshots_company').on(table.companyId)
  ]
)

// ==============================================================================
// 18. CURRENCY_REVALUATIONS (Period-End Foreign Exchange Revaluation Batches)
// Revalues foreign-currency monetary balances at month-end closing exchange rates
// ==============================================================================
export const currencyRevaluations = pgTable(
  'currency_revaluations',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    periodId: uuid('period_id')
      .notNull()
      .references(() => fiscalPeriods.id, { onDelete: 'restrict' }),
    currencyCode: varchar('currency_code', { length: 3 })
      .notNull()
      .references(() => currencies.code),
    rateUsed: numeric('rate_used', { precision: 20, scale: 6 }).notNull(),
    unrealizedGainLoss: numeric('unrealized_gain_loss', {
      precision: 18,
      scale: 2
    })
      .notNull()
      .default('0'),
    journalId: uuid('journal_id').references(() => journals.id, {
      onDelete: 'set null'
    }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdBy: uuid('created_by')
  },
  (table) => [
    index('idx_currency_revaluations_company').on(table.companyId),
    index('idx_currency_revaluations_period').on(table.periodId)
  ]
)
