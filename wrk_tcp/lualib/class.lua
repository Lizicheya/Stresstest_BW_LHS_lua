-- 简易 OOP 类工厂:基于表实现的类与继承,提供 new/ctor 等基础能力
function class(classname, super)
    -- 创建类,继承父类成员
    local cls = {super = super}
    if super then
        for k, v in pairs(super) do
            cls[k] = v
        end
    end 
    cls.__cname = classname
    -- 缺省构造函数,避免调用时为空
    if not cls.ctor then
        -- add default constructor
        cls.ctor = function() end
    end
    -- 实例化方法:拷贝类成员到实例并调用构造函数
    cls.new = function(...)
        local instance = {}
        for k, v in pairs(cls) do
            instance[k] = v
        end
        instance.class = cls
        instance:ctor(...)
        return instance
    end

    return cls
end
