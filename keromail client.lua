-- server pastebin is N8pH1Uj4

local title = "\n      KeroMail      "
            .. "\n---------------------"
 
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

function input_password()
    local contrasena = ""

    while true do
        local evento, tecla = os.pullEvent()

        if evento == "char" then
            contrasena = contrasena .. tecla
            term.write("*")  -- Muestra un asterisco en lugar del carácter real

        elseif evento == "key" then
            if tecla == keys.enter then
                print("") -- Salto de línea al terminar
                return contrasena
            elseif tecla == keys.backspace and #contrasena > 0 then
                contrasena = contrasena:sub(1, -2)  -- Elimina el último carácter
                local x, y = term.getCursorPos()
                term.setCursorPos(x - 1, y)
                term.write(" ") -- Borra el último asterisco
                term.setCursorPos(x - 1, y)
            end
        end
    end
end


function send(sesion)
    print("Destination Id: ")
    destinationId = read()
    print("Message:")
    text = read()
    text = sesion .. "|*|" .. cesar(text, shift(destinationId))
    print("\nEnviar? [y/n]")
    opt = ""
    while opt ~= "y" and opt ~= "n" do
        term.setCursorPos(1, 10)
        term.clearLine()
        opt = read()
    end
    if opt == "y" then
        pack = "s|*|" .. destinationId .. "|*|" .. text
        rednet.send(id, pack, "KEP")
    end
    if opt == "n" then
        print("\nCancelado")
    end
end
 
function receive(sesion)
    receiver_ID, verification = string.match(sesion, "^([^|]*)||([^|]*)$")
    pack = "r|*|receiver_req|*|" .. sesion .. "|*|fill_text"
    rednet.send(id, pack, "KEP")
    id, text, protocol = rednet.receive("KER", 5)
    if text ~= "No hay correo" then
        return cesar(text, -shift(receiver_ID))
    else
        return "No hay correo"
    end
end
 
function clear()
    term.clear()
    term.setCursorPos(1,1)
    print(title)  
end
 
function verify()
    sesion = ""
    clear()
    o = ""
    while o ~= "1" and o ~= "2" do
        print("Iniciar sesion: 1\nRegistrarse: 2")
        o = read()
        clear()
    end
    if o == "2" then
        password1 = "A"
        password2 = "B"
        print("Introduce nombre de usuario: ")
        username = read()
        clear()
        print("Introduce la contrase"..string.char(0xF1).."a: ")
        password1 = input_password()
        clear()
        print("Repite la contrase"..string.char(0xF1).."a: ")
        password2 = input_password()
        clear()
        if password1 == password2 and #password1 >= 4 then
            hashed_password = hash(password1 .. username)
            continue = ""
            while continue ~= "y" and continue ~= "n" do 
                print("Registrarse con nombre \"" .. username .. "\"? [y/n]")
                continue = read()
                clear()
                if continue == "y" then
                    pack = "g|*|register|*|" .. username .. "||" .. hashed_password .. "|*|" .. hashed_password
                    rednet.send(id, pack, "KEP")
                    id, response, protocol = rednet.receive("KER", 5)
                    if response == nil then
                        print("Fallo de conexion con el servidor")
                    else
                        print(response)
                    end
                end
            end
        elseif #password1 < 4 then
            print("La contrase"..string.char(0xF1).."a debe tener al menos 4 caracteres")
        else
            clear()
            print("Las contrase"..string.char(0xF1).."as no coinciden")
            clear()
        end
        sleep(1)
    elseif o == "1" then
        print("Introduce el nombre de usuario: ")
        username = read()
        clear()
        print("Introduce la contrase"..string.char(0xF1).."a: ")
        password = input_password()
        hashed_password = hash(password .. username)
        clear()
        pack = "l|*|login|*|" .. username .. "||" .. hashed_password .. "|*|" .. hashed_password
        rednet.send(id, pack, "KEP")
        id, response, protocol = rednet.receive("KER", 5)
        if response == nil then
            print("Fallo de conexion con el servidor")
        elseif response == "true" then
            print("Inicio de sesion correcto")
            sesion = username .. "||" .. hashed_password
            sleep(1)
        elseif response == "false" then
            print("Credenciales erroneas")
            sesion = ""
            sleep(1)
        else
            print("Error desconocido")
            sleep(1)
            sesion = ""
        end
    end
    return sesion
end
 
local modemSide = peripheral.find("modem")
if modemSide then
    -- Si se encuentra un modem, lo abre en ese lado
    side = peripheral.getName(modemSide)
    rednet.open(side)
    print("Conexion Rednet abierta en el lado " .. side)
    sleep(0.5)
else
    print("No se ha encontrado un modem conectado.")
    return
end
id = rednet.lookup("KEP", "KES")
clear()
if id == nil then
    print("Servidor offline\nTerminando...\n")
else
    sesion = verify()
    while sesion == "" do
        verify()
    end
    o = ""
    while o ~= "salir" and o ~= "s" and id ~= nill do
        clear()
        print("Elige opcion:")
        print("\"enviar\" o \"e\" para enviar keroMail")
        print("\"bandeja\" o \"b\" para descargar la bandeja de entrada")
        print("\"salir\" o \"s\" para salir")
        o = read()
        id = rednet.lookup("KEP", "KES")
        if id ~= nil then
            if o == "enviar" or o == "e" then
                clear()
                send(sesion)
            end
            if o == "bandeja" or o == "b" then
                clear()
                text = receive(sesion)
                file = fs.open("correo", "w")
                file.write(text)
                file.close()
                print("Se ha actualizado el correo")
                print("Checkea el fichero \"correo\"")
                print("Presiona cualquier tecla para continuar")
                os.pullEvent("key")
            end
        else
            print("Se ha perdido la conexion con el servidor")
        end
    end
    print("Saliendo...")
end 