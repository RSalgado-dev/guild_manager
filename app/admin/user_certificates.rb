ActiveAdmin.register UserCertificate do
  permit_params :user_id, :certificate_id, :granted_at, :expires_at, :status

  controller do
    def create
      build_resource
      resource.granted_by ||= current_user
      create!
    end
  end

  member_action :revoke, method: :post do
    resource.revoke!(revoked_by: current_user)
    redirect_to resource_path, notice: "Certificado revogado."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  action_item :revoke, only: :show, if: proc { resource.granted? } do
    link_to "Revogar", revoke_admin_user_certificate_path(resource), method: :post
  end

  index do
    selectable_column
    id_column
    column :user
    column :certificate
    column :status
    column :granted_by
    column :granted_at
    column :expires_at
    actions
  end

  filter :user
  filter :certificate
  filter :status, as: :select, collection: UserCertificate.statuses.keys
  filter :granted_at
  filter :expires_at

  form do |f|
    f.inputs "Concessão de certificado" do
      f.input :user
      f.input :certificate
      f.input :granted_at
      f.input :expires_at
      f.input :status, as: :select, collection: UserCertificate.statuses.keys
    end
    f.actions
  end

  show do
    attributes_table do
      row :user
      row :certificate
      row :status
      row :granted_by
      row :granted_at
      row :expires_at
    end
  end
end
