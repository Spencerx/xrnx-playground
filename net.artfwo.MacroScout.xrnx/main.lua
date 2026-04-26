local CONTROL_PORT = 43916
local RENOISE_PORT = 16385

local OscMessage = renoise.Osc.Message

local server, socket_error = renoise.Socket.create_server("localhost", RENOISE_PORT, renoise.Socket.PROTOCOL_UDP)

if (socket_error) then
  renoise.app():show_warning(("failed to create server. error: '%s'"):format(socket_error))
  return
end

local client, socket_error = renoise.Socket.create_client("localhost", CONTROL_PORT, renoise.Socket.PROTOCOL_UDP)

if (socket_error) then
  renoise.app():show_warning(("failed to create client. error: '%s'"):format(socket_error))
  return
end

function send_macro_names(instr)
  local macros = instr.macros  
  local macro_names = {}

  for i = 1,4 do
    if #macros[i].mappings > 0 then
      macro_names[i] = macros[i].name
    else
      macro_names[i] = 'n/a'
    end
  end
  
  client:send(
    OscMessage("/macro_scout/instrument", {
      {tag="s", value=instr.name},
      {tag="s", value=macro_names[1]},
      {tag="s", value=macro_names[2]},
      {tag="s", value=macro_names[3]},
      {tag="s", value=macro_names[4]},
    })
  )
end

server:run({
  socket_message = function(socket, data)
    local message_or_bundle, osc_error = renoise.Osc.from_binary_data(data)

    if (message_or_bundle) then
      if (type(message_or_bundle) == "Message") then
        print(("Got OSC message: '%s'"):format(tostring(message_or_bundle)))

        if message_or_bundle.pattern == "/macro_scout/port" then
          print("setting macro_scout port to "..message_or_bundle.arguments[1].value)
          CONTROL_PORT = message_or_bundle.arguments[1].value
        elseif message_or_bundle.pattern == "/macro_scout/instrument" then
          local i = message_or_bundle.arguments[1].value
          local instr = renoise.song().instruments[i]

          if instr then
            send_macro_names(instr)
          end
        end
      elseif (type(message_or_bundle) == "Bundle") then
        print(("Got OSC bundle: '%s'"):format(tostring(message_or_bundle)))
      end

    else
      print(("recv bad osc. error: '%s'"):format(osc_error))
    end
  end
})
