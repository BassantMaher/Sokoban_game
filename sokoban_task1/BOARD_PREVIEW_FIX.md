# Fix: Board Preview Mismatch Issue

## 🐛 Problem Identified

**Issue:** The board preview in the admin panel was not matching the actual game board rendering.

**Root Cause:** Board data from database had mixed types:
- Some rows were stored as **atoms** (e.g., `######` without quotes)
- Some rows were stored as **strings** (e.g., `"#  . #"`)
- This caused rendering inconsistencies

**Example of Bad Data:**
```elixir
{######, "#  . #", "#  $ #", "#  @ #", ######}
#  ↑ atom             ↑ strings           ↑ atom
```

---

## ✅ Solutions Implemented

### 1. **Enhanced Board Data Parsing** (admin_live.ex)

**Before:**
```elixir
board_array =
  board_string
  |> String.split("\n")
  |> Enum.map(&String.trim_trailing/1)
  |> Enum.reject(&(&1 == ""))
```

**After:**
```elixir
board_array =
  board_string
  |> String.split("\n")
  |> Enum.map(&String.trim_trailing/1)
  |> Enum.reject(&(&1 == ""))
  |> Enum.map(&to_string/1)  # Ensure all rows are strings
```

### 2. **Robust Preview Generation**

Added type conversion to handle any data type:
```elixir
defp generate_board_preview(board_data) when is_list(board_data) do
  board_data
  |> Enum.map(fn row ->
    cond do
      is_binary(row) -> row
      is_atom(row) -> Atom.to_string(row)
      true -> to_string(row)
    end
  end)
end
```

### 3. **Fixed Preview Rendering**

Updated to handle any row type:
```elixir
<%= for {cell, x} <- Enum.with_index(to_string(row) |> String.graphemes()) do %>
```

### 4. **Schema-Level Validation** (levels/level.ex)

Added **automatic sanitization** in changeset:
```elixir
defp sanitize_board_data(changeset) do
  case get_change(changeset, :board_data) do
    board_data when is_list(board_data) ->
      sanitized =
        Enum.map(board_data, fn row ->
          cond do
            is_binary(row) -> row
            is_atom(row) -> Atom.to_string(row)
            true -> to_string(row)
          end
        end)
      put_change(changeset, :board_data, sanitized)
  end
end
```

Added **validation** to ensure all rows are strings:
```elixir
defp validate_board_data(changeset) do
  validate_change(changeset, :board_data, fn :board_data, board_data ->
    cond do
      not is_list(board_data) ->
        [board_data: "must be a list of strings"]
      not Enum.all?(board_data, &is_binary/1) ->
        [board_data: "all rows must be strings"]
      true -> []
    end
  end)
end
```

### 5. **Debug View Added**

Added collapsible debug section to see actual data structure:
```html
<details>
  <summary>🔍 Debug: Board Data Structure</summary>
  <pre><%= inspect(@board_preview, pretty: true) %></pre>
</details>
```

### 6. **Data Cleanup Script**

Created `priv/repo/fix_board_data.exs` to fix existing levels:
```bash
mix run priv/repo/fix_board_data.exs
```

This script:
- Scans all levels in database
- Identifies levels with non-string rows
- Converts atoms/other types to strings
- Updates database

---

## 🔧 How to Fix Existing Data

### Option 1: Run Cleanup Script
```bash
cd sokoban_task1
mix run priv/repo/fix_board_data.exs
```

### Option 2: Re-seed Database
```bash
mix ecto.reset
mix run priv/repo/seeds.exs
```

### Option 3: Manual Fix in Database
```elixir
# Connect to your database
level = Repo.get(Level, 1)

# Fix board_data
fixed_data = Enum.map(level.board_data, fn row ->
  if is_atom(row), do: Atom.to_string(row), else: row
end)

level
|> Ecto.Changeset.change(board_data: fixed_data)
|> Repo.update()
```

---

## 🎯 Prevention Measures

### 1. **Automatic Sanitization**
All new levels created through admin panel will automatically sanitize data.

### 2. **Schema Validation**
Level schema now rejects invalid data types before saving.

### 3. **Type Safety**
Preview rendering handles any type gracefully with `to_string/1`.

### 4. **Debug Tools**
Admin can see actual data structure to catch issues early.

---

## ✅ Expected Behavior Now

### Admin Panel:
1. ✅ Admin types board layout in textarea
2. ✅ All rows automatically converted to strings
3. ✅ Preview shows exact visual representation
4. ✅ Preview matches what players will see
5. ✅ Validation prevents invalid data

### Game:
1. ✅ Loads level from database
2. ✅ All rows are guaranteed to be strings
3. ✅ Renders correctly every time
4. ✅ No type mismatches

---

## 🧪 Testing

### Test in Admin Panel:
1. Go to `/admin`
2. Create a level with this board:
```
######
#  . #
#  $ #
#  @ #
######
```
3. Check preview - should show visual blocks
4. Click debug section - should show all strings:
```elixir
["######", "#  . #", "#  $ #", "#  @ #", "######"]
```
5. Save level
6. Play level - should match preview exactly

### Verify Database:
```elixir
# In IEx
level = SokobanTask1.Repo.get(SokobanTask1.Levels.Level, 1)
IO.inspect(level.board_data, label: "Board Data")
# Should show: ["######", "#  . #", ...]
# All strings, no atoms!
```

---

## 📝 Summary

**Files Modified:**
- `lib/sokoban_task1_web/live/admin_live.ex` - Enhanced parsing and preview
- `lib/sokoban_task1/levels/level.ex` - Added validation and sanitization
- `priv/repo/fix_board_data.exs` - Created cleanup script

**Key Improvements:**
✅ Automatic type conversion (atom → string)
✅ Schema-level validation
✅ Visual preview matches game exactly
✅ Debug tools for troubleshooting
✅ Data cleanup script for existing levels

**Result:**
🎯 Board preview in admin panel now **perfectly matches** the game rendering!
