module OpinionatedPundit
  module Authorizable
    extend ActiveSupport::Concern

    included do |includer|
      OpinionatedPundit.register_rolable(includer)

      # Associations for the includer
      # ========================================================================
      has_many :role_grants, class_name: "OpinionatedPundit::RoleGrant", as: 'rolable'
      has_many :roles, through: :role_grants
      has_many :business_processes, through: :roles
      has_many :controller_actions, through: :business_processes


      # Associations for all other classes referencing the includer
      # ========================================================================
      includer_class_name = includer.model_name.to_s
      includer_pluralized_symbol = includer_class_name.underscore.pluralize.to_sym

      classes_to_extend = [OpinionatedPundit::Role,
                           OpinionatedPundit::BusinessProcess,
                           OpinionatedPundit::ControllerAction]

      # E.g. business_process has_many :users, through: role_grants, source_type: user
      # business_procces.pirates will find all pirates that have been granted that
      # business process
      classes_to_extend.each do |klass|
        klass.class_eval do
          has_many includer_pluralized_symbol,
                   through: :role_grants,
                   source_type: includer_class_name,
                   source: 'rolable'
        end
      end

    end

    # Mixed instance methods
    # ==========================================================================
    # Receives a stringified controller name and action name and verifies if
    # the caller has access to that endpoint
    def clear_for? controller:, action:
      controller_actions.exists?(controller: controller, action: action)
    end

    # Configure Includer for Authorization Admin
    # ==========================================================================
    class_methods do
      # Developers must use this method to register the includer on the
      # authorization admin specifying which field of attribute
      # (real or virtual)should be used in the admin to identify each
      # instance.
      # (e.g.  Users will be identified by :email)
      # TODO: Modify or remove this if getting rid of Rails Admin
      def register_in_authorization_admin(identifier:)
        OpinionatedPundit.register_authorizable_in_admin(self, identifier)
      end
    end

  end
end