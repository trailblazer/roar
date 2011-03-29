ActionController::TestCase.class_eval do
  # FIXME: ugly monkey-patching.
  # TODO: test:
  #   put :create
  #   put :create, :format => :xml
  #   put :create, "<order/>", :format => :xml
  #   put :create, "<order/>"
  def process(action, *args)
    if args.first.is_a?(String)
       request.env['RAW_POST_DATA'] = args.shift
       method = args.pop
       args << nil
       args << method
    end
    
    super
  end
  
  def assert_response(status, headers={})  # FIXME: allow message.
    super
    
    if headers.is_a?(Hash)
      assert_headers(headers)
    else
      assert_body(headers)
    end
  end
  
  def assert_headers(headers)
    headers.each_pair do |k,v|
      assert_equal v, @response.headers[k]
    end
  end
  
  def assert_body(body)
    assert_equal body, @response.body
  end
  
  
end
