class ActiveAdminPermissionAdapter < ActiveAdmin::AuthorizationAdapter
  RESOURCE_PERMISSIONS = {
    "Guild" => "manage_guild_settings",
    "User" => "manage_members",
    "Role" => "manage_roles",
    "PermissionGroup" => "manage_administrative_roles",
    "Squad" => "manage_members",
    "Event" => "manage_events",
    "EventParticipation" => "manage_events",
    "Mission" => "manage_missions",
    "MissionSubmission" => "review_mission_submissions",
    "Achievement" => "manage_achievements",
    "UserAchievement" => "grant_achievements",
    "Certificate" => "manage_certificates",
    "UserCertificate" => "grant_certificates",
    "RoleCertificateRequirement" => "manage_certificates",
    "CurrencyTransaction" => "manage_store",
    "AuditLog" => "view_audit_logs"
  }.freeze

  def authorized?(action, subject = nil)
    return false unless user
    return true if user.admin?
    return false unless user.has_guild_access?

    subject ||= default_subject
    return user.admin_panel_access? if dashboard_page?(subject)

    permission = permission_for(subject)
    return false unless permission
    return false if administrative_role_subject?(subject) && !user.has_permission?(:manage_administrative_roles)

    user.has_permission?(permission)
  end

  def scope_collection(collection, action = ActiveAdmin::Auth::READ)
    return collection if user&.admin?
    return collection.none unless user&.guild_id

    if collection.klass == User || collection.klass.column_names.include?("guild_id")
      collection.where(guild_id: user.guild_id)
    else
      collection
    end
  end

  private

  def default_subject
    resource.respond_to?(:resource_class) ? resource.resource_class : resource
  rescue NoMethodError
    resource
  end

  def dashboard_page?(subject)
    subject.is_a?(ActiveAdmin::Page) && subject.name == "Dashboard"
  end

  def permission_for(subject)
    RESOURCE_PERMISSIONS[subject_class_name(subject)]
  end

  def subject_class_name(subject)
    return subject.name if subject.is_a?(Class)

    subject.class.name
  end

  def administrative_role_subject?(subject)
    subject.is_a?(Role) && subject.administrative?
  end
end
