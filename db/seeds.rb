# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Idempotent by design: every record below is looked up with find_or_create_by
# before it is created, so running `rails db:seed` again (CI re-runs, a
# `docker compose up` restart, ...) never raises and never duplicates rows.
# See test/models/seeds_test.rb for the contract this file has to hold.
#
# Order matters — later steps depend on records created by earlier ones:
#   1. Role / Resource / RoleResource (permission tables, existing loaders)
#   2. Organization tree (one demo company, two departments)
#   3. Four demo users, one per role
#   4. One sample record per business line (Technology, Product + Instance
#      hierarchy, Matter)
#   5. Walk one ProductLog through the full approval flow so the demo isn't
#      all-drafts

# -- 1. Permissions -----------------------------------------------------
Role.load!
Resource.load!
RoleResource.load!

super_admin_role     = Role.find_by!(desc: 'super_admin')
develop_manager_role = Role.find_by!(desc: 'develop_manager')
developer_role       = Role.find_by!(desc: 'developer')
processer_role       = Role.find_by!(desc: 'processer')

# -- 2. Organization tree -------------------------------------------------
company = Organization.find_or_create_by!(name: 'Acme Manufacturing') do |org|
  org.desc = 'Demo manufacturing company'
end

engineering_dept = Organization.find_or_create_by!(name: 'Engineering Department') do |org|
  org.desc = 'Designs and releases parts and assemblies'
  org.parent = company
end

production_dept = Organization.find_or_create_by!(name: 'Production Department') do |org|
  org.desc = 'Runs process approval and final release'
  org.parent = company
end

# -- 3. Demo users, one per role, same password ---------------------------
# admin is deliberately the first user created: User#assign_super_admin_if_first_user
# would already promote it, but we assign the role explicitly too so this
# stays correct even if the users table isn't empty when seed runs.
admin = User.find_or_create_by!(login: 'admin') do |u|
  u.email = 'admin@example.com'
  u.name = 'Demo Admin'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.organization = company
end
admin.update!(role: super_admin_role)

devmgr = User.find_or_create_by!(login: 'devmgr') do |u|
  u.email = 'devmgr@example.com'
  u.name = 'Demo Development Manager'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.organization = engineering_dept
end
devmgr.update!(role: develop_manager_role)

dev = User.find_or_create_by!(login: 'dev') do |u|
  u.email = 'dev@example.com'
  u.name = 'Demo Developer'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.organization = engineering_dept
end
dev.update!(role: developer_role)

processer = User.find_or_create_by!(login: 'proc') do |u|
  u.email = 'proc@example.com'
  u.name = 'Demo Processer'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.organization = production_dept
end
processer.update!(role: processer_role)

# -- 4. One sample per business line --------------------------------------
technology = Technology.find_or_create_by!(no: 'PROC-001') do |t|
  t.name = 'Gearbox Machining Process'
  t.desc = 'Standard machining process for the gearbox housing and shaft.'
  t.valid_at = Time.current
  t.user = dev
end

product = Product.find_or_create_by!(product_no: 'PRD-001') do |p|
  p.name = 'Gearbox Assembly'
  p.desc = 'Demo gearbox assembly used to showcase the product workflow.'
  p.norms = 'GB/T 1184'
  p.user = dev
  p.technology = technology
end
product.organizations << engineering_dept unless product.organizations.include?(engineering_dept)

# Instance hierarchy (a small BOM tree): housing is the top-level part on the
# product, bearing nests under it via ancestry — this is what
# ApplicationHelper#tree_rows walks (Product -> instances -> children).
housing = Instance.find_or_create_by!(instance_no: 'PRT-001') do |i|
  i.name = 'Gearbox Housing'
  i.desc = 'Cast aluminum housing for the gearbox assembly.'
  i.norms = 'GB/T 1176'
  i.user = dev
  i.technology = technology
end
housing.organizations << engineering_dept unless housing.organizations.include?(engineering_dept)

bearing = Instance.find_or_create_by!(instance_no: 'PRT-002') do |i|
  i.name = 'Output Shaft Bearing'
  i.desc = 'Sealed ball bearing for the output shaft.'
  i.norms = '6205-2RS'
  i.user = dev
  i.parent = housing
end
bearing.organizations << engineering_dept unless bearing.organizations.include?(engineering_dept)

product.instances << housing unless product.instances.include?(housing)

matter = Matter.find_or_create_by!(name: 'Gearbox Assembly BOM Release') do |m|
  m.desc = 'Bill of materials release for the gearbox assembly demo.'
  m.user = dev
end

# -- 5. Walk one ProductLog through the full approval flow ----------------
# develop_id/flow_id/active_id are the three approvers this workflow expects
# at every step (see LogWorkflow's validates_presence_of); the demo users
# double up in those roles so the flow can complete end to end.
product_log = ProductLog.find_or_create_by!(product: product, user: dev) do |log|
  log.develop_id = devmgr.id
  log.flow_id = processer.id
  log.active_id = admin.id
  log.file_name = 'gearbox-assembly.pdf'
  log.file_path = 'demo/gearbox-assembly.pdf'
end

# Only walk a freshly-created log forward — on a repeat `db:seed` run,
# find_or_create_by! above returns the already-active log untouched, and
# AASM would raise InvalidTransition if we tried to do_apply! it again.
if product_log.status == 'wait'
  product_log.do_apply!
  product_log.do_develop_audit!
  product_log.do_flow_audit!
  product_log.do_active_audit!
end
