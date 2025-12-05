---@class Core.Math.PointSet
local M = {}
Core.Math.PointSet = M

function M.EllipsePoint(x, y, hr, vr, erot, a)
    local x0, y0 = cos(a) * hr, sin(a) * vr
    return
    x + x0 * cos(erot) - y0 * sin(erot),
    y + y0 * cos(erot) + x0 * sin(erot)
end

---等角椭圆上的点
function M.Ellipse2Point(x, y, hr, vr, erot, a)
    a = a % 360
    if a % 90 ~= 0 then
        local add = 0
        if a > 90 and a < 180 then
            add = 180
        elseif a > 180 and a < 270 then
            add = -180
        end
        a = atan(tan(a) * hr / vr) + add
    end
    local x0, y0 = cos(a) * hr, sin(a) * vr
    return
    x + x0 * cos(erot) - y0 * sin(erot),
    y + y0 * cos(erot) + x0 * sin(erot)
end

---心形上的点
function M.HeartPoint(x, y, r, hrot, a)
    hrot = hrot - 90---由于0度是正上，为了对齐，调整一下度数
    local c = sin(a)
    local x0 = r * c * c * c
    local y0 = r * cos(a) - r * 0.37 * cos(a * 2) - r * 0.16 * cos(a * 3)--调整形状
    return
    x + x0 * cos(hrot) - y0 * sin(hrot),
    y + y0 * cos(hrot) + x0 * sin(hrot)
end

---正多边形上的点（等角）
---@param d number@半径
---@param n number@边数
function M.PolygonPoint(x, y, d, n, rrot, a)
    --a = a - rrot
    d = d * cos(180 / n)
    local A
    local da = 360 / n
    local x0, y0
    for o = 0, n - 1 do
        A = (a - o * da) % 360
        if A > 180 then
            A = A - 360
        end
        if A < (da / 2) and A >= -(da / 2) then
            x0, y0 = Core.Math.PolarToCart(d / cos(A), A + o * da)
            break
        end
    end
    return
    x + x0 * cos(rrot) - y0 * sin(rrot),
    y + y0 * cos(rrot) + x0 * sin(rrot)
end

---正多边形上的点（等距）
---@param d number@半径
---@param n number@边数
---@param depart number@每边分割成几段
---@param p number@第几点
function M.Polygon2Point(x, y, d, n, rrot, depart, p)
    d = d * cos(180 / n)
    local X = 1 / tan((180 - 360 / n) / 2) * d
    rrot = rrot + 360 / n * int(p / depart)
    p = p % depart
    X = X - 2 * X / depart * p
    return
    x + X * cos(rrot) - d * sin(rrot),
    y + X * sin(rrot) + d * cos(rrot)
end

---角度迭代器(360/n)
---@param n number@增次
---@param ia number@初始角
---@return fun():number,number
function M.AngleIterator(ia, n)
    local index = 0
    local da = 360 / n
    ia = ia - da
    return function()
        if index < n then
            index = index + 1
            return ia + da * index, index
        end
    end
end

---椭圆坐标迭代器
---@return fun():number,number,number
function M.EllipseIterator(ia, n, x, y, hr, vr, erot)
    local index = 0
    local da = 360 / n
    return function()
        if index < n then
            index = index + 1
            return index, M.EllipsePoint(x, y, hr, vr, erot, ia + da * index)
        end
    end
end

---等角椭圆坐标迭代器
---@return fun():number,number,number
function M.Ellipse2Iterator(ia, n, x, y, hr, vr, erot)
    local index = 0
    local da = 360 / n
    return function()
        if index < n then
            index = index + 1
            return index, M.Ellipse2Point(x, y, hr, vr, erot, ia + da * index)
        end
    end
end

---心形坐标迭代器
---@return fun():number,number,number
function M.HeartIterator(ia, n, x, y, r, hrot)
    local index = 0
    local da = 360 / n
    return function()
        if index < n then
            index = index + 1
            return index, M.HeartPoint(x, y, r, hrot, ia + da * index)
        end
    end
end

---正多边形坐标迭代器（等角）
---n为边数的倍数最佳，倍数为奇数时无尖角，倍数为偶数时有尖角
---@param pn number@多边形边数
---@param d number@多边形对角线长
---@return fun():number,number,number
function M.PolygonIterator(ia, n, x, y, d, pn, rrot)
    local index = 0
    local da = 360 / n
    return function()
        if index < n then
            index = index + 1
            return index, M.PolygonPoint(x, y, d, pn, rrot, ia + da * index)
        end
    end
end

---正多边形坐标迭代器（等距）
---@param pn number@多边形边数
---@param d number@多边形对角线长
---@return fun():number,number,number
function M.Polygon2Iterator(rrot, n, x, y, d, pn)
    local index = 0
    local depart = n / pn
    return function()
        if index < n then
            index = index + 1
            return index, M.Polygon2Point(x, y, d, pn, rrot, depart, index)
        end
    end
end