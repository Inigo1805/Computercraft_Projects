-- client pastebin is gZqEqzzw
 
function cesar(texto, shift)
    local resultado = ""
    for i = 1, #texto do
        local c = texto:sub(i, i)
        local byte = c:byte()
 
        if byte >= 65 and byte <= 90 then  -- Mayúsculas A-Z
            byte = ((byte - 65 + shift) % 26) + 65
        elseif byte >= 97 and byte <= 122 then  -- Minúsculas a-z
            byte = ((byte - 97 + shift) % 26) + 97
        end
 
        resultado = resultado .. string.char(byte)
    end
    return resultado
end

-- XOR bit a bit usando operaciones aritméticas
function bit_xor(a, b)
    local result = 0
    local power = 1
    while a > 0 or b > 0 do
        local bit_a = a % 2  -- Obtiene el bit menos significativo de 'a'
        local bit_b = b % 2  -- Obtiene el bit menos significativo de 'b'
        local xor_bit = (bit_a + bit_b) % 2  -- XOR: 1 si son distintos, 0 si son iguales
        result = result + xor_bit * power
        a = math.floor(a / 2)  -- Desplaza 'a' a la derecha
        b = math.floor(b / 2)  -- Desplaza 'b' a la derecha
        power = power * 2  -- Mueve el resultado una posición a la izquierda
    end
    return result
end

-- djb2a modificado para ComputerCraft
function hash(str)
    local h = 5381
    for i = 1, #str do
        h = bit_xor(h, ((h * 32) + math.floor(h / 4) + string.byte(str, i))) % 4294967296
    end
    return string.format("%08x", h)  -- Representación en hexadecimal
end

function shift(text)
    local sum = 0
    for i = 1, #text do
        sum = sum + string.byte(text, i)
    end
    return (sum % 26) + 1 -- Shift en el rango [1, 26]
end
 
function insertarSaltosDeLinea(texto)
    maxLength = 39
    local resultado = ""
    local line = ""
    
    -- Divide el texto en palabras
    for palabra in texto:gmatch("%S+") do
        -- Si la longitud de la línea más la nueva palabra es mayor que el límite
        if #line + #palabra + 1 > maxLength then
            -- Si la línea no está vacía, añade un salto de línea
            if #line > 0 then
                resultado = resultado .. line .. "\n"
            end
            -- Comienza una nueva línea con la palabra actual
            line = palabra
        else
            -- Añade la palabra a la línea actual (con un espacio)
            if #line > 0 then
                line = line .. " " .. palabra
            else
                line = palabra
            end
        end
    end
    
    -- Añadir la última línea al resultado
    if #line > 0 then
        resultado = resultado .. line
    end
    
    return resultado
end
 
local modemSide = peripheral.find("modem")
if modemSide then
    -- Si se encuentra un modem, lo abre en ese lado
    side = peripheral.getName(modemSide)
    rednet.open(side)
    print("Conexion Rednet abierta en el lado " .. side)
    sleep(1)
else
    print("No se ha encontrado un modem conectado.")
    return
end
term.clear()
rednet.host("KEP", "KES")
print("Hosting Kero's eMail Server Receiver")
print("------------------------------------")
local segundos = 0
local time_last_email = "NEVER"
local patron = "^(%a)|%*|([^|%*|]+)|%*|([^|%*|]+||[^|%*|]+)|%*|(.+)$"
while modemSide do
    term.setCursorPos(1,5)
    term.clearLine()
    print("Initiated for " .. segundos ..
        " seconds")
    term.setCursorPos(1,6)
    term.clearLine()
    print("Last email in second: " ..
        time_last_email)
    segundos = segundos + 1
    senderID, text, protocol = 
        rednet.receive("KEP", 1)
    if protocol == "KEP" then
        mode, destination, sender, rest = 
            string.match(text, patron)
        sender_ID, verification = string.match(sender, "^([^|]*)||([^|]*)$")
        if mode == "s" then
            filename = "users"
            local file = fs.open(filename, "r")
            if file then
                local content = file.readAll()
                file.close()
                if string.match(content, "^" .. sender_ID .. " " .. verification) or string.match(content, "\n" .. sender_ID .. " " .. verification) then
                    time_last_email = segundos
                    filename = "mails/" .. destination
                    local file = fs.open(filename,"r")
                    if file == nil then
                        previous = ""
                    else
                        previous = file.readAll()
                        file.close()
                    end
                    file = fs.open(filename, "w")
                    date = os.date()
                    file.write(
                        cesar("From: " .. sender_ID 
                        .. ", at " .. date ..  "\n\"" 
                        .. insertarSaltosDeLinea(cesar(rest, -shift(destination)))
                        .. "\"" .. "\n---------------------------------------\n", 
                        shift(destination)) .. previous)
                    file.close()
                end
            end
        elseif mode == "r" then
            local file = fs.open("users", "r")
            if file then
                local content = file.readAll()
                file.close()
                if string.match(content, "^" .. sender_ID .. " " .. verification) or string.match(content, "\n" .. sender_ID .. " " .. verification) then
                    filename = "mails/" .. sender_ID
                    file = fs.open(filename, "r")
                    if file == nil then
                        content = "No hay correo"
                    else
                        content = file.readAll()
                    end
                    rednet.send(senderID, content, "KER")
                end
            end
        elseif mode == "g" then
            filename = "users"
            local file = fs.open(filename, "r")
            if file then
                local content = file.readAll()
                file.close()
                if string.match(content, "^" .. sender_ID .. " ") or string.match(content, "\n" .. sender_ID .. " ") then
                    response = "ERROR Nombre de usuario ya registrado"
                else
                    file = fs.open(filename, "a")
                    file.write(sender .. " " .. rest .. "\n")
                    file.close()
                    response = "Usuario registrado correctamente"
                end
            else
                file = fs.open(filename, "a")
                file.write(sender_ID .. " " .. rest .. "\n")
                file.close()
                response = "Usuario registrado correctamente"
            end
            rednet.send(senderID, response, "KER")
        elseif mode == "l" then
            response = "false"
            filename = "users"
            local file = fs.open(filename, "r")
            if file then
                local content = file.readAll()
                file.close()
                if string.match(content, "^" .. sender_ID .. " " .. rest) or string.match(content, "\n" .. sender_ID .. " " .. rest) then
                    response = "true"
                end
            end
            rednet.send(senderID, response, "KER")
        end
    end
end
rednet.unhost("KEP", "KES")
print("Hosting terminated")