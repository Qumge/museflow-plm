require 'test_helper'

class TreeRowsTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    @user = create_user(login: 'tr', role: create_role('super_admin'))
  end

  test "product rows are followed by their parts at depth one" do
    product = create_product(user: @user, product_no: 'P-T1')
    part = create_instance(user: @user, instance_no: 'I-T1')
    product.instances = [part]

    rows = tree_rows(Product.where(id: product.id))

    assert_equal 2, rows.size
    assert_equal product, rows[0][:record]
    assert_equal 0, rows[0][:depth]
    assert_equal part, rows[1][:record]
    assert_equal 1, rows[1][:depth]
  end

  test "a product without parts yields a single row" do
    product = create_product(user: @user, product_no: 'P-T2')

    rows = tree_rows(Product.where(id: product.id))

    assert_equal 1, rows.size
    assert_equal 0, rows[0][:depth]
  end

  test "instance ancestry nests recursively, depth derived from tree position" do
    root = create_instance(user: @user, instance_no: 'I-ROOT')
    child = create_instance(user: @user, instance_no: 'I-CHILD', parent: root)
    grandchild = create_instance(user: @user, instance_no: 'I-GRANDCHILD', parent: child)

    rows = tree_rows(Instance.where(id: root.id))

    assert_equal 3, rows.size
    assert_equal [root, child, grandchild], rows.map { |row| row[:record] }
    assert_equal [0, 1, 2], rows.map { |row| row[:depth] }
  end

  test "a product's part expands its own ancestry children beneath it" do
    product = create_product(user: @user, product_no: 'P-T3')
    part = create_instance(user: @user, instance_no: 'I-T3')
    sub_part = create_instance(user: @user, instance_no: 'I-T3-SUB', parent: part)
    product.instances = [part]

    rows = tree_rows(Product.where(id: product.id))

    assert_equal [product, part, sub_part], rows.map { |row| row[:record] }
    assert_equal [0, 1, 2], rows.map { |row| row[:depth] }
  end

  # 工艺文件的子行是"用到这份工艺的零件与产品"——平铺的引用关系，不是
  # BOM 那样的层级。递归展开会让同一个零件出现两次（一次作为工艺的直接
  # 子行，一次作为产品的子行），所以走 technology_tree_rows 而非 tree_rows。
  test "a process document lists the parts and products that use it, flat" do
    tech = create_technology(user: @user, no: 'T-C1')
    part = create_instance(user: @user, instance_no: 'I-C1', technology: tech)
    product = create_product(user: @user, product_no: 'P-C1', technology: tech)

    rows = technology_tree_rows(Technology.where(id: tech.id))

    assert_equal 3, rows.size,
                 '平铺一层：工艺文件本身 + 用到它的零件 + 用到它的产品，不得重复'
    assert_equal 0, rows[0][:depth]
    children = rows[1..].map { |r| r[:record] }
    assert_includes children, part
    assert_includes children, product
    assert rows[1..].all? { |r| r[:depth] == 1 }
  end
end
