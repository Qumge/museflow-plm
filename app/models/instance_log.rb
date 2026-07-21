class InstanceLog < ApplicationRecord
  include LogWorkflow

  log_owner :instance
end
