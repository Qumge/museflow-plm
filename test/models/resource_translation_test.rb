require 'test_helper'

# P4 Task 8a：config/resources.yml 与 config/role_resources.yml 的 49
# 个（实测 92 个，见 task-7-9-report.md）唯一中文显示名已翻成英文。这个
# 测试把"翻完之后不能再悄悄漏回中文"钉成一个可执行的不变量，而不是只靠
# 人工过一遍——任何人往这两个清单里加新权限时，如果又写回中文 name，会
# 立刻在这里炸掉，而不是等到英文 locale 走查才发现。
class ResourceTranslationTest < ActiveSupport::TestCase
  CJK = /\p{Han}/

  test "resources.yml display names contain no Chinese characters" do
    offenders = Resource.manifest.flat_map do |target, actions|
      actions.select { |_action, name| name.match?(CJK) }.map { |action, name| "#{target}.#{action}: #{name}" }
    end

    assert_empty offenders, "config/resources.yml 里这些权限名还没翻英:\n#{offenders.join("\n")}"
  end

  test "role_resources.yml display names contain no Chinese characters" do
    config = YAML.load_file(Rails.root.join('config', 'role_resources.yml'))
    offenders = config.flat_map do |role, targets|
      targets.flat_map do |target, actions|
        actions.select { |_action, name| name.match?(CJK) }
               .map { |action, name| "#{role}.#{target}.#{action}: #{name}" }
      end
    end

    assert_empty offenders, "config/role_resources.yml 里这些权限名还没翻英:\n#{offenders.join("\n")}"
  end
end
