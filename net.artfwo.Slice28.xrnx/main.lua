function slice28()
  chop(8)
end

function chop(n_slices)
    local sample = renoise.song().selected_instrument.samples[1]
    
    while #sample.slice_markers > 0 do
        sample:delete_slice_marker(sample.slice_markers[1])
    end

    for i = 0, n_slices - 1, 1 do
      sample:insert_slice_marker(1 + math.floor(i * 
      sample.sample_buffer.number_of_frames / n_slices))
    end
end

renoise.tool():add_menu_entry {
  name = "Sample Editor:Slices:Slice28",
  invoke = function()
    slice28()
  end
}

renoise.tool():add_keybinding{
  name = 'Sample Editor:Slices:Slice28',
  invoke = function()
    slice28()
  end
}
