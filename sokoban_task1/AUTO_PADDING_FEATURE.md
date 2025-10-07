# Auto-Padding Feature for Admin Level Creator

## 🎯 Feature Overview

Automatically pads incomplete board rows with walls (`#`) to ensure consistent grid display and prevent confusion when creating levels.

---

## ✨ How It Works

### **Problem Solved:**
When an admin creates a level with rows of different lengths, the display can look inconsistent and confusing. For example:

**Before (inconsistent):**
```
#####
#@$.#
##
```
- Row 1: 5 chars
- Row 2: 5 chars  
- Row 3: 2 chars ❌

**After (auto-padded):**
```
#####
#@$.#
#####
```
- Row 1: 5 chars
- Row 2: 5 chars
- Row 3: 5 chars ✅ (padded with 3 walls)

### **Rules:**
1. Find the **maximum row length** (or minimum 12 columns)
2. Pad **shorter rows** with walls (`#`) on the right
3. **Visual indicator** shows which walls were auto-added
4. **Warning message** alerts admin about padding

---

## 🔧 Implementation Details

### 1. **Backend Logic** (`admin_live.ex`)

#### Normalization Function:
```elixir
defp normalize_board_width(board_data) do
  # Find max width, but at least 12
  max_width =
    board_data
    |> Enum.map(&String.length/1)
    |> Enum.max()
    |> max(12)

  # Pad each row to max_width
  Enum.map(board_data, fn row ->
    current_length = String.length(row)
    
    if current_length < max_width do
      padding = String.duplicate("#", max_width - current_length)
      row <> padding
    else
      row
    end
  end)
end
```

#### Padding Detection:
```elixir
defp has_padding?(original_board, padded_board) do
  Enum.zip(original_board, padded_board)
  |> Enum.any?(fn {original, padded} ->
    String.length(to_string(original)) < String.length(to_string(padded))
  end)
end

defp is_padded_cell?(x, y, original_board) do
  original_row = Enum.at(original_board, y)
  original_length = String.length(to_string(original_row))
  x >= original_length  # Cell is beyond original length
end
```

### 2. **Visual Indicators** (CSS)

#### Padded Wall Styling:
```css
.padded-wall {
  background: linear-gradient(135deg, var(--purple-700), var(--purple-800));
  border: 1px solid var(--purple-600);
  opacity: 0.7;  /* Slightly dimmed */
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05);
}

/* Diagonal stripe pattern */
.padded-wall::after {
  content: '';
  background: repeating-linear-gradient(
    45deg,
    transparent,
    transparent 3px,
    rgba(255, 255, 255, 0.05) 3px,
    rgba(255, 255, 255, 0.05) 6px
  );
}
```

**Visual Effect:**
- Padded walls are **slightly dimmed** (70% opacity)
- Subtle **diagonal stripes** pattern
- Different from regular walls

### 3. **UI Warnings**

#### Info Box (always visible):
```html
<div class="bg-purple-50 border border-purple-200 rounded-lg p-2">
  💡 Auto-padding: Rows shorter than the longest row will be 
  automatically padded with walls (#) on the right
</div>
```

#### Warning Alert (when padding is applied):
```html
<div class="bg-yellow-50 border-l-4 border-yellow-500 rounded">
  ⚠️ Auto-padding applied: Some rows were extended with 
  walls to match the longest row
</div>
```

#### Note (when padding is applied):
```html
💡 Note: Walls with slightly dimmed appearance indicate 
auto-padded areas
```

### 4. **Debug Section**

Shows both original and padded board data:
```
Original (before padding):
["#####", "#@$.#", "##"]

After padding:
["#####", "#@$.#", "#####"]
```

---

## 🎨 Visual Examples

### Example 1: Short Rows
**Input:**
```
#####
#@$.#
##
```

**Preview:**
- First 2 rows: Normal walls
- Last row: 2 normal walls + 3 **dimmed padded walls** with stripes

### Example 2: Very Short Row
**Input:**
```
############
#@  .    $ #
#
```

**Preview:**
- Row 1: All normal
- Row 2: All normal
- Row 3: 1 normal wall + 11 **dimmed padded walls**

### Example 3: Less than 12 columns
**Input:**
```
#####
#@$.#
#####
```
(Only 5 columns)

**Preview:**
All rows padded to 12 columns:
```
#####       (5 normal + 7 padded)
#@$.#       (5 normal + 7 padded)
#####       (5 normal + 7 padded)
```

---

## 📋 User Experience Flow

1. **Admin creates level** with uneven rows
2. **Types in textarea:**
   ```
   #####
   #@$.#
   ##
   ```

3. **Sees info box:** "Rows will be auto-padded"

4. **Preview updates** showing:
   - ⚠️ Yellow warning: "Auto-padding applied"
   - Visual grid with dimmed padded walls
   - 💡 Note about dimmed walls

5. **Admin can:**
   - See exactly what will be saved
   - Adjust if needed
   - Or accept auto-padding

6. **Saves level** - padding is permanent

---

## ✅ Benefits

1. **Prevents Confusion:**
   - Consistent grid width
   - No jagged edges
   - Clear boundaries

2. **Visual Feedback:**
   - See which walls are auto-added
   - Dimmed appearance for clarity
   - Warning messages

3. **Flexible:**
   - Minimum 12 columns guaranteed
   - Adapts to any size
   - Right-side padding only

4. **Automatic:**
   - No manual calculation needed
   - Works on validation
   - Updates live preview

5. **Transparent:**
   - Debug section shows data
   - Before/after comparison
   - Clear documentation

---

## 🧪 Testing

### Test Case 1: Uneven Rows
```
Input:
#####
#@$.#
##

Expected:
- All rows become 5 chars
- Last row gets 3 padded walls
- Warning message shown
```

### Test Case 2: Very Small Grid
```
Input:
###
#@#

Expected:
- All rows become 12 chars (minimum)
- 9 padded walls per row
- Warning message shown
```

### Test Case 3: Already Consistent
```
Input:
#####
#@$.#
#####

Expected:
- All rows become 12 chars (minimum)
- 7 padded walls per row
- Warning message shown
```

### Test Case 4: Large Grid
```
Input:
################
#@$.         ###

Expected:
- Both rows are 16 chars
- Second row stays same
- No warning (already consistent)
```

---

## 📝 Files Modified

1. **`lib/sokoban_task1_web/live/admin_live.ex`**
   - Added `normalize_board_width/1`
   - Added `has_padding?/2`
   - Added `is_padded_cell?/3`
   - Updated `generate_board_preview/1`
   - Updated `get_preview_cell_classes/5`
   - Enhanced UI with warnings

2. **`assets/css/app.css`**
   - Added `.padded-wall` class
   - Dimmed appearance (70% opacity)
   - Diagonal stripe pattern
   - Distinct from normal walls

---

## 🎯 Result

Admins can now create levels with any row length, and the system will:
- ✅ Automatically pad to consistent width
- ✅ Show visual indicators
- ✅ Display clear warnings
- ✅ Maintain minimum 12 columns
- ✅ Prevent confusion

The preview **exactly matches** what players will see, with clear distinction between original and padded walls! 🎮✨
