class TechnologyLog < ApplicationRecord
  include LogWorkflow

  log_owner :technology
end
