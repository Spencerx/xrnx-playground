local CONTROL_PORT = 43915
local RENOISE_PORT = 16384

local OscMessage = renoise.Osc.Message

local server, socket_error = renoise.Socket.create_server("localhost", RENOISE_PORT, renoise.Socket.PROTOCOL_UDP)

if (socket_error) then
  renoise.app():show_warning(("failed to create server. error: '%s'"):format(socket_error))
  return
end

server:run({
  socket_message = function(socket, data)
    local message_or_bundle, osc_error = renoise.Osc.from_binary_data(data)

    -- show what we've got
    if (message_or_bundle) then
      if (type(message_or_bundle) == "Message") then
        print(("Got OSC message: '%s'"):format(tostring(message_or_bundle)))

        if message_or_bundle.pattern == "/arc_control/port" then
          print("setting arc_control port to "..message_or_bundle.arguments[1].value)
          CONTROL_PORT = message_or_bundle.arguments[1].value
        end
      elseif (type(message_or_bundle) == "Bundle") then
        print(("Got OSC bundle: '%s'"):format(tostring(message_or_bundle)))
      else
        -- never will get in here
      end

    else
      print(("recv bad osc. error: '%s'"):format(osc_error))
    end
  end
})

local client, socket_error = renoise.Socket.create_client("localhost", CONTROL_PORT, renoise.Socket.PROTOCOL_UDP)

if (socket_error) then
  renoise.app():show_warning(("failed to create client. error: '%s'"):format(socket_error))
  return
end

function instrument_changed()
  local instrument_index = renoise.song().selected_instrument_index
  local instrument = renoise.song().selected_instrument
  local macros = instrument.macros
  
  client:send(
    OscMessage("/arc_control/macro", {
      {tag="i", value=instrument_index},
      {tag="f", value=macros[1].value},
      {tag="f", value=macros[2].value},
      {tag="f", value=macros[3].value},
      {tag="f", value=macros[4].value},
    })
  )
  
  -- send labels for mapped macros
  local macro_names = {}
  for i = 1,4 do
    if #macros[i].mappings > 0 then
      macro_names[i] = macros[i].name
    else
      macro_names[i] = 'n/a'
    end
  end
  
  client:send(
    OscMessage("/arc_control/label", {
      {tag="i", value=instrument_index},
      {tag="s", value=macro_names[1]},
      {tag="s", value=macro_names[2]},
      {tag="s", value=macro_names[3]},
      {tag="s", value=macro_names[4]},
    })
  )

  -- send instrument name for soyuz/ui  
  client:send(
    OscMessage("/arc_control/instrument_name", {
      {tag="i", value=instrument_index},
      {tag="s", value=instrument.name},
    })
  )
end

function new_song()
  renoise.song().selected_instrument_index_observable:add_notifier(instrument_changed)
  instrument_changed()
end

renoise.tool().app_new_document_observable:add_notifier(new_song)
