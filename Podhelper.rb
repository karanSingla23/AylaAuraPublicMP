# helper methods for Podfile
# assign value to var if not a defined environment variable or is empty
def conditional_assign(name, value)
    return if instance_variable_get("@#{name}") != nil and not instance_variable_get("@#{name}").empty?

    if !ENV.has_key?(name.upcase) or ENV[name.upcase].empty?
        instance_variable_set("@#{name}", value)
    else
        instance_variable_set("@#{name}", ENV[name.upcase])
    end
end

#reopen String class to add green method
class String
  def green
    "\e[32m#{self}\e[0m"
  end
end

# @person ? @person.name : nil /*vs*/ @person.try(:name)
class Object
  def try(method)
    send method if respond_to? method
  end
end

# for app rel_branch example: "release/4.3.0"
# find most stable lib release like 4.3.20
def get_latest_lib_branch(rel_branch, repo)
    ver_fields=rel_branch.split('.')
    major_minor=ver_fields[0] + '.' + ver_fields[1]

    total_branches=`git ls-remote #{repo} | grep #{major_minor}`
    max_sub_minor_int = 0
    max_sub_minor_str = "00"
    total_branches.split('\n').each do |line|
        subminor = line.split(major_minor)[-1].split('.')[-1]
        subminor_int = subminor.to_i
        if (subminor_int >= max_sub_minor_int)
            max_sub_minor_int = subminor_int
            max_sub_minor_str = subminor
        end
    end

    (major_minor + '.' + max_sub_minor_str).chomp!
end

