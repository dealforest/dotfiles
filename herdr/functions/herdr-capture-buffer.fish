function herdr-capture-buffer
    set -l file "/tmp/herdr.buffer"
    herdr pane get-content > "$file"
    echo "buffer saved to $file"
end
