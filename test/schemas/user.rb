schema do
  str! :first_name
  str! :last_name
  ary? :groups do
    ref 'nested/group'
  end
end
