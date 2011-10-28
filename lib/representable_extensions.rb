Representable::Definition.class_eval do
  # Populate the representer's attribute with the right value.
  def populate(representer, attributes)
    representer.public_send("#{accessor}=", attributes[accessor])
  end
end
