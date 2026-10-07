module Api
  module V1
    class DataExportsController < BaseApiController
      skip_before_action :authenticate_from_token!

      def download_exported_data
        token = params[:token]
        data_export = CheckDataExport.where(token: token).first
        s3_url = nil
        if data_export && current_api_user
          ability = Ability.new(current_api_user, data_export.team)
          if ability.can?(:read, data_export)
            s3_url = CheckS3.presigned_url(data_export.s3_key, CheckConfig.get('regenerate_download_expire_value', 30, :integer).minutes.to_i, CheckConfig.get('check_sunset_s3_bucket'))
            data_export.use_count = data_export.use_count + 1
            data_export.skip_check_ability = true
            data_export.save!
          end
        end
        s3_url.nil? ? render_error('Unrecognized client', 'INVALID_VALUE') : (render json: { url: s3_url })
      end
    end
  end
end
