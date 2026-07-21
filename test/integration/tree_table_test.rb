require 'test_helper'

# P5 Task 6：把产品/零件/工艺文件的层级表从客户端渲染（bootstrap-treetable.js
# 在浏览器里用 JSON 拼表格）改成服务端渲染（app/views/shared/_list.html.erb
# 直接吐出完整的 <tr data-depth="N">）。
#
# 这个文件在 P4 建立时断言的是 products_tree / instances_tree /
# technologies_tree 三个 helper 产出的 JSON 契约——那三个 helper 随 Task 6
# 一起删除了，JSON 契约不再存在。这里整个改写：不再检查 JSON，直接对 HTTP
# 响应的 HTML 做 assert_select，断言树该有的行真的渲染出来了。这正是本阶段
# 要消除的盲区（客户端渲染的东西，HTTP 测试永远够不到）的直接对治——
# 服务端化之前，这些断言必然失败，因为 HTML 里根本没有这些 <tr>。
class TreeTableTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(login: 'tree_table_tester', role: create_role('super_admin'))
    sign_in_as @admin
  end

  test "the products list renders parts nested under their product" do
    product = create_product(user: @admin, product_no: 'P-N1')
    part = create_instance(user: @admin, instance_no: 'I-N1')
    product.instances = [part]

    get products_path

    assert_response :success
    assert_select "tr[data-depth='0'] td", text: /P-N1/
    assert_select "tr[data-depth='1'] td", text: /I-N1/
    # 编号列的链接目标要由 record.class 推导（Product -> /products/:id,
    # Instance -> /instances/:id），不是靠中文 model_type 字符串比较——
    # 这是 P4 解耦掉的东西，这里钉住不许退化。
    assert_select "tr[data-depth='0'] a[href=?]", product_path(product), text: /P-N1/
    assert_select "tr[data-depth='1'] a[href=?]", instance_path(part), text: /I-N1/
  end

  # BOM 树是真层级：一个零件自己的子零件（ancestry children）应该继续往下
  # 铺一层，而不是被拍平到跟它的父产品同一层。tree_rows_test.rb 已经在
  # helper 单元测试层面钉住这一点；这里在 HTTP 层面再钉一次，确认
  # products/_list.html.erb 真的把 tree_rows 的递归结果原样渲染出来了，
  # 不是只截取了前两层。
  test "a part's own sub-parts render one level deeper than the part itself" do
    product = create_product(user: @admin, product_no: 'P-N2')
    part = create_instance(user: @admin, instance_no: 'I-N2')
    sub_part = create_instance(user: @admin, instance_no: 'I-N2-SUB', parent: part)
    product.instances = [part]

    get products_path

    assert_response :success
    assert_select "tr[data-depth='0'] td", text: /P-N2/
    assert_select "tr[data-depth='1'] td", text: /I-N2/
    assert_select "tr[data-depth='2'] td", text: /I-N2-SUB/
  end

  test "the instances list nests ancestry children under their parent" do
    root = create_instance(user: @admin, instance_no: 'I-ROOT-N')
    child = create_instance(user: @admin, instance_no: 'I-CHILD-N', parent: root)

    get instances_path

    assert_response :success
    assert_select "tr[data-depth='0'] td", text: /I-ROOT-N/
    assert_select "tr[data-depth='1'] td", text: /I-CHILD-N/
    assert_select "tr[data-depth='0'] a[href=?]", instance_path(root), text: /I-ROOT-N/
    assert_select "tr[data-depth='1'] a[href=?]", instance_path(child), text: /I-CHILD-N/
  end

  # 工艺文件 -> 用到它的零件/产品是平铺的引用关系，不是层级。这里钉住两件事：
  # 用到它的零件和产品都渲染在 depth 1（不是 depth 0 也不是各自往下再递归），
  # 并且整页压根不存在 depth 2 的行——递归展开会让同一个零件在产品那一支
  # 下又出现一次，这个断言直接堵死那种回归。
  test "the technologies list is flat: the part and product that use it both render at depth 1" do
    tech = create_technology(user: @admin, no: 'T-N1')
    part = create_instance(user: @admin, instance_no: 'I-N3', technology: tech)
    product = create_product(user: @admin, product_no: 'P-N3', technology: tech)

    get technologies_path

    assert_response :success
    assert_select "tr[data-depth='0'] td", text: /T-N1/
    assert_select "tr[data-depth='1'] td", text: /I-N3/
    assert_select "tr[data-depth='1'] td", text: /P-N3/
    assert_select "tr[data-depth='2']", 0
  end
end
