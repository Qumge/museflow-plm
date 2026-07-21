class AuditsController < ApplicationController

  def index

  end

  def products
    @apply_product_logs = current_user.develop_product_logs.where(status: 'apply').order('product_logs.updated_at desc')
    @develop_product_logs = current_user.flow_product_logs.where(status: 'develop').order('product_logs.updated_at desc')
    @flow_product_logs = current_user.active_product_logs.where(status: 'flow').order('product_logs.updated_at desc')
  end

  def instances
    @apply_instance_logs = current_user.develop_instance_logs.where(status: 'apply').order('instance_logs.updated_at desc')
    @develop_instance_logs = current_user.flow_instance_logs.where(status: 'develop').order('instance_logs.updated_at desc')
    @flow_instance_logs = current_user.active_instance_logs.where(status: 'flow').order('instance_logs.updated_at desc')
  end

  def technologies
    @apply_technology_logs = current_user.develop_technology_logs.where(status: 'apply').order('technology_logs.updated_at desc')
    @develop_technology_logs = current_user.flow_technology_logs.where(status: 'develop').order('technology_logs.updated_at desc')
    @flow_technology_logs = current_user.active_technology_logs.where(status: 'flow').order('technology_logs.updated_at desc')
  end

end
