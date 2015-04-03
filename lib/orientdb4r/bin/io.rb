require 'bindata'
require 'orientdb4r/bin/constants'

module Orientdb4r

  module Binary

    module OIO

      def req_resp(socket, req, resp)
        req.write(socket)

        status = BinData::Int8.read(socket).to_i
        if ::Orientdb4r::Binary::Constants::STATUS_ERROR == status
          errors = protocol::Errors.read(socket)
          exceptions = errors[:exceptions]
          Orientdb4r::logger.error "exception(s): #{exceptions}"

          # if exceptions[0] && exceptions[0][:exception_class] == "com.orientechnologies.orient.core.exception.ORecordNotFoundException"
          #   raise RecordNotFound.new(session)
          # else
          #  raise ServerError.new(session, *exceptions)
          # end
          raise ServerError, exceptions[0..-2]
        end

BinData::trace_reading do
        resp.read(socket)
end
        resp
      end


    end

  end

end
