schema do
  str! :name
  ary? :users do
    ref 'user'
  end
end
