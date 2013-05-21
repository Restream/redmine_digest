Deface::Override.new(
  :virtual_path => 'users/_preferences',
  :name => 'my_digest_enabled',
  :insert_before => 'code:contains("end"):last',
  :text => '<% if User.current.admin? %><p><%= pref_fields.check_box :digest_enabled %></p><% end %>')
