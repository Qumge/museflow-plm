require 'test_helper'

# P4 Task 1（回归测试网）Step 1。
#
# `Resource.load!`（app/models/resource.rb:31）用
# `find_or_create_by(action:, name:, target:)` 定位现有行——`name` 参与了
# 查找条件。P4 Task 2a 要把权限显示名从中文翻成英文，这会在无数据迁移的
# 情况下把 `name` 全部改掉；若不先把 `name` 从查找条件里移出去，
# 任何一次改名后重跑 `load!` 都会把旧行留在原地、再插入一行新的，
# 产生数据污染（角色仍指向旧行，`can?` 判定不受影响，但 Resource 表膨胀、
# 旧行成为死数据）。
#
# 本文件在 Task 2a 修复前只覆盖"清单不变"这一种幂等场景；
# "清单值被改过"的场景已实测复现（见下方 skip 用例），留给 Task 2a 转绿。
class ResourceLoadTest < ActiveSupport::TestCase
  test "load! is idempotent when the manifest is unchanged" do
    Resource.load!
    count_after_first_load = Resource.count

    Resource.load!

    assert_equal count_after_first_load, Resource.count,
                 'running load! twice with an unchanged manifest must not create duplicate rows'
  end

  # --------------------------------------------------------------------
  # 实测复现（2026-07-20，本地 museflow_test 库，测试库经 schema:load 后无
  # 存量脏数据，manifest 共 89 项，故基线为 89，而非需求文档中给出的开发库
  # 基线 90/91——同一个 bug，只是两个库的起始行数不同）：
  #
  #   Resource.load!                                   # => Resource.count == 89
  #   r = Resource.find_by!(action: 'index', target: 'products')
  #   r.update!(name: "#{r.name} (edited)")
  #   Resource.load!
  #   Resource.count                                    # => 90
  #
  # 原始失败输出（去 skip 后跑 `bin/rails test
  # test/models/resource_load_test.rb`）：
  #
  #   Failure:
  #   ResourceLoadTest#test_load!_does_not_duplicate_a_resource_whose_name_was_edited_out-of-band [test/models/resource_load_test.rb:57]:
  #   load! must stay idempotent even if a resource's display name was
  #   edited out-of-band (e.g. by a future i18n translation pass)..
  #   Expected: 89
  #     Actual: 90
  #
  # 完整输出已记入 .superpowers/sdd/task-1-report.md。
  # --------------------------------------------------------------------
  test "load! does not duplicate a resource whose name was edited out-of-band" do
    Resource.load!
    count_after_first_load = Resource.count

    edited = Resource.find_by!(action: 'index', target: 'products')
    edited.update!(name: "#{edited.name} (edited)")

    Resource.load!

    assert_equal count_after_first_load, Resource.count,
                 "load! must stay idempotent even if a resource's display name was " \
                 'edited out-of-band (e.g. by a future i18n translation pass).'
  end
end
