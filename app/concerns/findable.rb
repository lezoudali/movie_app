module Findable
  def find_all_by_name(search_name)
    name_regex = /#{search_name.strip}/i 
    all.find_all{ |object| object.name.match(name_regex)}
  end

  def find_by_name(search_name)
    name_regex = /#{search_name.strip}/i 
    all.find{ |object| object.name.match(name_regex)}
  end
end
