module EncodingHelper
  extend self

  def encode!(message)
    return nil unless message.respond_to? :force_encoding

    # if message is utf-8 encoding, just return it
    message.force_encoding("UTF-8")
    return message if message.valid_encoding?

    # return message if message type is binary
    detect = CharlockHolmes::EncodingDetector.detect(message)
    return message.force_encoding("BINARY") if detect && detect[:type] == :binary

    # encoding message to detect encoding
    # Force encoding only if we have high confidence. The confidence threshold
    # is tuned so that all test cases pass. It needs to be greater than
    # 33% (don't force encoding) and less than 44% (force encoding).
    if detect && detect[:encoding] && detect[:confidence] > 40
      message.force_encoding(detect[:encoding])
    end

    # encode and clean the bad chars
    message.replace clean(message)
  rescue
    encoding = detect ? detect[:encoding] : "unknown"
    "--broken encoding: #{encoding}"
  end

  def encode_utf8(message)
    detect = CharlockHolmes::EncodingDetector.detect(message)
    detect_all = CharlockHolmes::EncodingDetector.detect_all(message)
    if detect && detect[:confidence] > 40
      CharlockHolmes::Converter.convert(message, detect[:encoding], 'UTF-8')
    else
      clean(message)
    end
  end

  private

  def clean(message)
    message.encode("UTF-16BE", undef: :replace, invalid: :replace, replace: "")
           .encode("UTF-8")
           .gsub("\0".encode("UTF-8"), "")
  end
end
