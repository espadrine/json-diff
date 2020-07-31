module JsonDiff
  class V2
    attr_reader :opts, :changes

    def self.diff(before, after, opts = {})
      runner = new(opts)
      runner.diff(before, after)
      runner.changes
    end

    def initialize(opts = {})
      @opts = opts
      @changes  = []
    end

    def diff_hash(before, after, path)
      lost = before.keys - after.keys
      lost.each do |key|
        inner_path = JsonDiff.extend_json_pointer(path, key)
        changes << JsonDiff.remove(inner_path, include_was(path) ? before[key] : nil)
      end

      if include_addition(:hash, path)
        gained = after.keys - before.keys
        gained.each do |key|
          inner_path = JsonDiff.extend_json_pointer(path, key)
          changes << JsonDiff.add(inner_path, after[key])
        end
      end

      kept = before.keys & after.keys
      kept.each do |key|
        inner_path = JsonDiff.extend_json_pointer(path, key)
        diff(before[key], after[key], inner_path)
      end
    end

    def diff_array(before, after, path)
      if before.size == 0
        if include_addition(:array, path)
          after.each_with_index do |item, index|
            inner_path = JsonDiff.extend_json_pointer(path, index)
            changes << JsonDiff.add(inner_path, item)
          end
        end
      elsif after.size == 0
        before.each do |item|
          # Delete elements from the start.
          inner_path = JsonDiff.extend_json_pointer(path, 0)
          changes << JsonDiff.remove(inner_path, include_was(path) ? item : nil)
        end
      else
        pairing = JsonDiff.array_pairing(before, after, opts)
        # FIXME: detect replacements.

        # All detected moves that do not reach the similarity limit are deleted
        # and re-added.
        pairing[:pairs].select! do |pair|
          sim = pair[2]
          kept = (sim >= 0.5)
          if !kept
            pairing[:removed] << pair[0]
            pairing[:added] << pair[1]
          end
          kept
        end

        pairing[:pairs].each do |pair|
          before_index, after_index = pair
          inner_path = JsonDiff.extend_json_pointer(path, before_index)
          diff(before[before_index], after[after_index], inner_path)
        end

        if !original_indices(path)
          # Recompute indices to account for offsets from insertions and
          # deletions.
          pairing = JsonDiff.array_changes(pairing)
        end

        pairing[:removed].each do |before_index|
          inner_path = JsonDiff.extend_json_pointer(path, before_index)
          changes << JsonDiff.remove(inner_path, include_was(path) ? before[before_index] : nil)
        end

        pairing[:pairs].each do |pair|
          before_index, after_index = pair
          inner_before_path = JsonDiff.extend_json_pointer(path, before_index)
          inner_after_path = JsonDiff.extend_json_pointer(path, after_index)

          if before_index != after_index && include_moves(path)
            changes << JsonDiff.move(inner_before_path, inner_after_path)
          end
        end

        if include_addition(:array, path)
          pairing[:added].each do |after_index|
            inner_path = JsonDiff.extend_json_pointer(path, after_index)
            changes << JsonDiff.add(inner_path, after[after_index])
          end
        end
      end
    end

    def diff(before, after, path = '')
      if before.is_a?(Hash)
        if !after.is_a?(Hash)
          changes << JsonDiff.replace(path, include_was(path) ? before : nil, after)
        else
          diff_hash(before, after, path)
        end
      elsif before.is_a?(Array)
        if !after.is_a?(Array)
          changes << JsonDiff.replace(path, include_was(path) ? before : nil, after)
        else
          diff_array(before, after, path)
        end
      else
        if before != after
          changes << JsonDiff.replace(path, include_was(path) ? before : nil, after)
        end
      end
    end

    def include_addition(type, path)
      return true if opts[:additions] == nil
      opts[:additions].respond_to?(:call) ? opts[:additions].call(type, path) : opts[:additions]
    end

    def include_moves(path)
      return true if opts[:moves] == nil
      opts[:moves].respond_to?(:call) ? opts[:moves].call(path) : opts[:moves]
    end

    def include_was(path)
      return false if opts[:include_was] == nil
      opts[:include_was].respond_to?(:call) ? opts[:include_was].call(path) : opts[:include_was]
    end

    def original_indices(path)
      return false if opts[:original_indices] == nil
      opts[:original_indices].respond_to?(:call) ? opts[:original_indices].call(path) : opts[:original_indices]
    end
  end
end
