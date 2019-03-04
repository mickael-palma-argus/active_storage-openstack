# frozen_string_literal: true

module ActiveStorage
  module Openstack
    # :reek:IrresponsibleModule
    class Client
      # :reek:IrresponsibleModule
      class Storage
        # Create a tempory URL according to OpenStack specification.
        # More details here: https://docs.openstack.org/swift/latest/api/temporary_url_middleware.html
        class CreateTemporaryURL
          attr_reader :uri, :method, :options

          def initialize(uri:, method:, options: {})
            @uri = uri
            @method = method
            @options = options
          end

          def generate
            add_params
            uri.to_s
          end

          private

          def add_params
            uri.query = URI.encode_www_form(
              temp_url_sig: signature,
              temp_url_expires: expires_in,
              filename: filename,
              disposition => nil
            )
          end

          def signature
            OpenSSL::HMAC.hexdigest(algorithm, temporary_url_key, hmac_body)
          end

          def expires_in
            @expires_in ||= options.fetch(:expires_in) do
              15.minutes.from_now.to_i
            end
          end

          def filename
            File.basename(uri.path)
          end

          def disposition
            options.fetch(:disposition) { 'inline' }
          end

          def algorithm
            'SHA1'
          end

          def temporary_url_key
            options.fetch(:temporary_url_key) do
              Rails.application.credentials.openstack.fetch(:temporary_url_key)
            end
          end

          def hmac_body
            <<~TXT.strip
              #{method}
              #{expires_in}
              #{uri.path}
            TXT
          end
        end
        private_constant :CreateTemporaryURL
      end
    end
  end
end
