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
  departments
} from './org'
import { users } from './auth'
import { accounts } from './gl'

// ==============================================================================
// 1. PAYMENT_TERMS (Payment Terms Master: Net 30, Net 60, COD, etc.)
// Reusable commercial credit terms for customers and suppliers
// ==============================================================================
export const paymentTerms = pgTable(
  'payment_terms',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id').references(() => companies.id, {
      onDelete: 'restrict'
    }), // NULL = tenant-wide standard payment terms
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 100 }).notNull(),
    days: integer('days').notNull().default(0), // Due in days (0 = COD / Immediate)
    discountDays: integer('discount_days').default(0), // Early payment discount days
    discountPercentage: numeric('discount_percentage', {
      precision: 5,
      scale: 2
    }).default('0'), // Cash discount percentage (e.g. 2.00 for 2/10 Net 30)
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
    check('chk_payment_terms_days', sql`${table.days} >= 0`),
    check('chk_payment_terms_disc_days', sql`${table.discountDays} >= 0`),
    check('chk_payment_terms_disc_pct', sql`${table.discountPercentage} >= 0`),
    uniqueIndex('uq_payment_terms_tenant_code').on(
      table.tenantId,
      table.companyId,
      table.code
    ),
    index('idx_payment_terms_tenant').on(table.tenantId),
    index('idx_payment_terms_company').on(table.companyId)
  ]
)

// ==============================================================================
// 2. CUSTOMER_GROUPS (Customer Classification: Retail, Wholesale, VIP, Corporate)
// Grouping for default pricing tiers, credit policies, and sales reporting
// ==============================================================================
export const customerGroups = pgTable(
  'customer_groups',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id').references(() => companies.id, {
      onDelete: 'restrict'
    }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 100 }).notNull(),
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
    uniqueIndex('uq_customer_groups_tenant_company_code').on(
      table.tenantId,
      table.companyId,
      table.code
    ),
    index('idx_customer_groups_tenant').on(table.tenantId),
    index('idx_customer_groups_company').on(table.companyId)
  ]
)

// ==============================================================================
// 3. CUSTOMERS (Customer Master Data with Credit Limits and AR Account)
// Authoritative debtor master data with credit control and billing configuration
// ==============================================================================
export const customers = pgTable(
  'customers',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    groupId: uuid('group_id').references(() => customerGroups.id, {
      onDelete: 'set null'
    }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    taxId: varchar('tax_id', { length: 64 }), // NPWP 16 digits
    creditLimit: numeric('credit_limit', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    termId: uuid('term_id').references(() => paymentTerms.id, {
      onDelete: 'set null'
    }),
    arAccountId: uuid('ar_account_id').references(() => accounts.id, {
      onDelete: 'set null'
    }),
    currencyCode: varchar('currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    email: varchar('email', { length: 255 }),
    phone: varchar('phone', { length: 64 }),
    address: text('address'),
    notes: text('notes'),
    isBlocked: boolean('is_blocked').notNull().default(false), // Credit lock flag
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
    check('chk_customers_credit_limit', sql`${table.creditLimit} >= 0`),
    uniqueIndex('uq_customers_tenant_company_code').on(
      table.tenantId,
      table.companyId,
      table.code
    ),
    index('idx_customers_tenant').on(table.tenantId),
    index('idx_customers_company').on(table.companyId),
    index('idx_customers_group').on(table.groupId),
    index('idx_customers_ar_account').on(table.arAccountId),
    index('idx_customers_active')
      .on(table.companyId, table.isActive)
      .where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 4. CUSTOMER_CONTACTS (Contact Persons at Customer)
// Key stakeholder and billing contacts attached to customer accounts
// ==============================================================================
export const customerContacts = pgTable(
  'customer_contacts',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    customerId: uuid('customer_id')
      .notNull()
      .references(() => customers.id, { onDelete: 'cascade' }),
    name: varchar('name', { length: 180 }).notNull(),
    title: varchar('title', { length: 100 }), // Job title / Role
    email: varchar('email', { length: 255 }),
    phone: varchar('phone', { length: 64 }),
    isPrimary: boolean('is_primary').notNull().default(false),
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
    index('idx_customer_contacts_customer').on(table.customerId),
    index('idx_customer_contacts_tenant').on(table.tenantId)
  ]
)

// ==============================================================================
// 5. SUPPLIER_GROUPS (Supplier Classification: Trade, Non-Trade, Service, Import)
// Strategic procurement categorization for reporting and spend analytics
// ==============================================================================
export const supplierGroups = pgTable(
  'supplier_groups',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id').references(() => companies.id, {
      onDelete: 'restrict'
    }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 100 }).notNull(),
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
    uniqueIndex('uq_supplier_groups_tenant_company_code').on(
      table.tenantId,
      table.companyId,
      table.code
    ),
    index('idx_supplier_groups_tenant').on(table.tenantId),
    index('idx_supplier_groups_company').on(table.companyId)
  ]
)

// ==============================================================================
// 6. SUPPLIERS (Supplier Master Data with Terms, AP Account, and Bank Details)
// Authoritative vendor master data for procurement and accounts payable
// ==============================================================================
export const suppliers = pgTable(
  'suppliers',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    groupId: uuid('group_id').references(() => supplierGroups.id, {
      onDelete: 'set null'
    }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    taxId: varchar('tax_id', { length: 64 }), // Corporate NPWP 16 digits
    termId: uuid('term_id').references(() => paymentTerms.id, {
      onDelete: 'set null'
    }),
    apAccountId: uuid('ap_account_id').references(() => accounts.id, {
      onDelete: 'set null'
    }),
    currencyCode: varchar('currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    email: varchar('email', { length: 255 }),
    phone: varchar('phone', { length: 64 }),
    bankName: varchar('bank_name', { length: 100 }),
    bankAccountNo: varchar('bank_account_no', { length: 64 }),
    bankAccountName: varchar('bank_account_name', { length: 180 }),
    address: text('address'),
    notes: text('notes'),
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
    uniqueIndex('uq_suppliers_tenant_company_code').on(
      table.tenantId,
      table.companyId,
      table.code
    ),
    index('idx_suppliers_tenant').on(table.tenantId),
    index('idx_suppliers_company').on(table.companyId),
    index('idx_suppliers_group').on(table.groupId),
    index('idx_suppliers_ap_account').on(table.apAccountId),
    index('idx_suppliers_active')
      .on(table.companyId, table.isActive)
      .where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 7. SUPPLIER_CONTACTS (Contact Persons at Supplier)
// Key sales representatives and order coordinators at vendor organizations
// ==============================================================================
export const supplierContacts = pgTable(
  'supplier_contacts',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    supplierId: uuid('supplier_id')
      .notNull()
      .references(() => suppliers.id, { onDelete: 'cascade' }),
    name: varchar('name', { length: 180 }).notNull(),
    title: varchar('title', { length: 100 }),
    email: varchar('email', { length: 255 }),
    phone: varchar('phone', { length: 64 }),
    isPrimary: boolean('is_primary').notNull().default(false),
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
    index('idx_supplier_contacts_supplier').on(table.supplierId),
    index('idx_supplier_contacts_tenant').on(table.tenantId)
  ]
)

// ==============================================================================
// 8. SALESPERSONS (Salesperson Master: Employee Assigned to Sales)
// Sales representative entity linked to user accounts and department scope
// ==============================================================================
export const salespersons = pgTable(
  'salespersons',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    userId: uuid('user_id').references(() => users.id, {
      onDelete: 'set null'
    }),
    departmentId: uuid('department_id').references(() => departments.id, {
      onDelete: 'set null'
    }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 180 }).notNull(),
    email: varchar('email', { length: 255 }),
    phone: varchar('phone', { length: 64 }),
    commissionRate: numeric('commission_rate', { precision: 5, scale: 2 })
      .default('0'), // Percentage commission
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
    check('chk_salesperson_commission', sql`${table.commissionRate} >= 0`),
    uniqueIndex('uq_salespersons_company_code').on(
      table.companyId,
      table.code
    ),
    index('idx_salespersons_tenant').on(table.tenantId),
    index('idx_salespersons_company').on(table.companyId),
    index('idx_salespersons_department').on(table.departmentId),
    index('idx_salespersons_user').on(table.userId)
  ]
)

// ==============================================================================
// 9. PRICE_LISTS (Price List Master: Standard, Retail, Distributor, Promo)
// Pricing tier containers scoped by company and currency with validity periods
// ==============================================================================
export const priceLists = pgTable(
  'price_lists',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 180 }).notNull(),
    currencyCode: varchar('currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    description: text('description'),
    isDefault: boolean('is_default').notNull().default(false),
    validFrom: date('valid_from'),
    validTo: date('valid_to'),
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
    check(
      'chk_price_lists_valid_dates',
      sql`${table.validTo} IS NULL OR ${table.validFrom} IS NULL OR ${table.validTo} >= ${table.validFrom}`
    ),
    uniqueIndex('uq_price_lists_company_code').on(table.companyId, table.code),
    index('idx_price_lists_tenant').on(table.tenantId),
    index('idx_price_lists_company').on(table.companyId)
  ]
)

// ==============================================================================
// 10. PRICE_LIST_ITEMS (Item Prices in a Price List)
// Specific product pricing with tiered minimum quantity break points
// Note: itemId represents future linkage to Phase E items master
// ==============================================================================
export const priceListItems = pgTable(
  'price_list_items',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    priceListId: uuid('price_list_id')
      .notNull()
      .references(() => priceLists.id, { onDelete: 'cascade' }),
    itemId: uuid('item_id').notNull(), // Target item in Phase E inventory
    unitPrice: numeric('unit_price', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    minQuantity: numeric('min_quantity', { precision: 18, scale: 4 })
      .notNull()
      .default('1'),
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
    check('chk_price_list_items_price', sql`${table.unitPrice} >= 0`),
    check('chk_price_list_items_min_qty', sql`${table.minQuantity} > 0`),
    uniqueIndex('uq_price_list_items_key').on(
      table.priceListId,
      table.itemId,
      table.minQuantity
    ),
    index('idx_price_list_items_list').on(table.priceListId),
    index('idx_price_list_items_item').on(table.itemId)
  ]
)

// ==============================================================================
// 11. CUSTOMER_PRICINGS (Customer-Specific Pricing Overrides)
// Contract or negotiated pricing overriding standard price lists for key accounts
// ==============================================================================
export const customerPricings = pgTable(
  'customer_pricings',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    customerId: uuid('customer_id')
      .notNull()
      .references(() => customers.id, { onDelete: 'cascade' }),
    itemId: uuid('item_id').notNull(), // Target item in Phase E inventory
    specialPrice: numeric('special_price', { precision: 18, scale: 2 }).notNull(),
    currencyCode: varchar('currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    validFrom: date('valid_from'),
    validTo: date('valid_to'),
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
    check('chk_customer_pricing_price', sql`${table.specialPrice} >= 0`),
    check(
      'chk_customer_pricing_dates',
      sql`${table.validTo} IS NULL OR ${table.validFrom} IS NULL OR ${table.validTo} >= ${table.validFrom}`
    ),
    uniqueIndex('uq_customer_pricing_key').on(
      table.customerId,
      table.itemId,
      table.validFrom
    ),
    index('idx_customer_pricing_tenant').on(table.tenantId),
    index('idx_customer_pricing_company').on(table.companyId),
    index('idx_customer_pricing_customer').on(table.customerId),
    index('idx_customer_pricing_item').on(table.itemId)
  ]
)

// ==============================================================================
// 12. DISCOUNT_RULES (Discount Rule Definitions: Percentage, Fixed, Tiered)
// Automated discount evaluation rules based on customer classification or order total
// ==============================================================================
export const discountRules = pgTable(
  'discount_rules',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 180 }).notNull(),
    discountType: varchar('discount_type', { length: 20 })
      .notNull()
      .default('percentage'), // 'percentage', 'fixed_amount', 'tiered'
    discountValue: numeric('discount_value', { precision: 18, scale: 2 })
      .notNull()
      .default('0'),
    minOrderAmount: numeric('min_order_amount', { precision: 18, scale: 2 })
      .default('0'),
    customerGroupId: uuid('customer_group_id').references(
      () => customerGroups.id,
      { onDelete: 'set null' }
    ),
    validFrom: date('valid_from'),
    validTo: date('valid_to'),
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
    check(
      'chk_discount_rules_type',
      sql`${table.discountType} IN ('percentage', 'fixed_amount', 'tiered')`
    ),
    check('chk_discount_rules_value', sql`${table.discountValue} >= 0`),
    check('chk_discount_rules_min_order', sql`${table.minOrderAmount} >= 0`),
    check(
      'chk_discount_rules_dates',
      sql`${table.validTo} IS NULL OR ${table.validFrom} IS NULL OR ${table.validTo} >= ${table.validFrom}`
    ),
    uniqueIndex('uq_discount_rules_company_code').on(
      table.companyId,
      table.code
    ),
    index('idx_discount_rules_tenant').on(table.tenantId),
    index('idx_discount_rules_company').on(table.companyId),
    index('idx_discount_rules_group').on(table.customerGroupId)
  ]
)
