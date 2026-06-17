# How to add a new Creature to Idydle

The system is now **Resource-driven**, which means you don't need to touch `Creature.gd` to add a new species.

### Step 1: Create the Data Resource
1.  In the Godot **FileSystem** dock, right-click and choose **New > Resource...**
2.  Search for **CreatureData** and click **Create**.
3.  Save it as `Cow.tres` (for example).
4.  In the **Inspector**, fill in the details:
    *   **Species Name**: "Cow"
    *   **Produce Amount**: 5
    *   **Produce Time**: 15.0
    *   **Resource Type**: "Stone" (or "Wood"/"Berry")
    *   **Sound Text**: "Moo!"
    *   **Icon**: (Optional) Drag a texture here.

### Step 2: Create the Creature Scene
1.  Open `cat.tscn` or `chicken.tscn`.
2.  Go to **Scene > Save Scene As...** and save it as `cow.tscn`.
3.  Select the **Root Node** (the CharacterBody2D).
4.  In the **Inspector**, look for the **Data** property.
5.  Drag your `Cow.tres` from the FileSystem into that slot.
6.  Change the **AnimatedSprite2D** frames to use your cow art.

### Step 3: Profit!
Now, whenever you place `cow.tscn` in your game world, it will automatically:
*   Wait 15 seconds.
*   Produce 5 Stone.
*   Print "Cow dit : Moo!" in the console.

---

**Note**: To make the creature actually "buyable" or "spawnable" from a menu, you would follow a similar pattern to the `CraftingMenu.tscn`, adding a `CreatureData` array to your spawner script.
