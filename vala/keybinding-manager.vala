/*
valac --pkg gtk+-2.0 --pkg x11 --pkg gdk-x11-2.0 --pkg gee-1.0 keybinding-manager.vala
*/

using Gtk;
using Gdk;
using X;

/**
 * This class is in charge to grab keybindings on the X11 display
 * and filter X11-events and passing on such events to the registed
 * handler methods.
 * 
 * @author Oliver Sauder <os@esite.ch>
 */
public class KeybindingManager : GLib.Object
{
    /**
     * list of binded keybindings
     */
    private List<Keybinding> bindings = new List<Keybinding>();
 
    /**
     * locked modifiers used to grab all keys whatever lock key
     * is pressed.
     */
    private static uint[] lock_modifiers = {
        0,
        Gdk.ModifierType.MOD2_MASK, // NUM_LOCK
        Gdk.ModifierType.LOCK_MASK, // CAPS_LOCK
        Gdk.ModifierType.MOD5_MASK, // SCROLL_LOCK
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK,
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.MOD5_MASK,
        Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK,
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK
    };
 
    /**
     * Helper class to store keybinding
     */
    private class Keybinding
    {
        public Keybinding(string accelerator, int keycode,
            Gdk.ModifierType modifiers, KeybindingHandlerFunc handler)
        {
            this.accelerator = accelerator;
            this.keycode = keycode;
            this.modifiers = modifiers;
            this.handler = handler;
        }
 
        public string accelerator { get; set; }
        public int keycode { get; set; }
        public Gdk.ModifierType modifiers { get; set; }
        public KeybindingHandlerFunc handler { get; set; }
    }
 
    /**
     * Keybinding func needed to bind key to handler
     * 
     * @param event passing on gdk event
     */
    public delegate void KeybindingHandlerFunc(Gdk.Event event);
 
    public KeybindingManager()
    {
        // init filter to retrieve X.Events
        Gdk.Window rootwin = Gdk.get_default_root_window();
        if(rootwin != null) {
            rootwin.add_filter(event_filter);
        }
    }
 
    /**
     * Bind accelerator to given handler
     *
     * @param accelerator accelerator parsable by Gtk.accelerator_parse
     * @param handler handler called when given accelerator is pressed
     */
    public void bind(string accelerator, KeybindingHandlerFunc handler)
    {
        debug("Binding key " + accelerator);
 
        // convert accelerator
        uint keysym;
        Gdk.ModifierType modifiers;
        Gtk.accelerator_parse(accelerator, out keysym, out modifiers);
 
        unowned X.Display display = Gdk.x11_get_default_xdisplay();
        X.Window window = Gdk.x11_get_default_root_xwindow();
        int keycode = display.keysym_to_keycode(keysym);            
 
        if(keycode != 0) {
            // trap XErrors to avoid closing of application
            // even when grabing of key fails
            Gdk.error_trap_push();
 
            // grab key finally
            // also grab all keys which are combined with a lock key such NumLock
            foreach(uint lock_modifier in lock_modifiers) {     
                display.grab_key(keycode, modifiers|lock_modifier, window, false,
                    X.GrabMode.Async, X.GrabMode.Async);
            }
 
            // wait until all X request have been processed
            Gdk.flush();
 
            // store binding
            Keybinding binding = new Keybinding(accelerator, keycode, modifiers, handler);
            bindings.append(binding);
 
            debug("Successfully binded key " + accelerator);
        }
    }
 
    /**
     * Unbind given accelerator.
     *
     * @param accelerator accelerator parsable by Gtk.accelerator_parse
     */
    public void unbind(string accelerator)
    {
        debug("Unbinding key " + accelerator);
 
        unowned X.Display display = Gdk.x11_get_default_xdisplay();
        X.Window window = Gdk.x11_get_default_root_xwindow();
 
        // unbind all keys with given accelerator
        List<Keybinding> remove_bindings = new List<Keybinding>();
        foreach(Keybinding binding in bindings) {
            if(str_equal(accelerator, binding.accelerator)) {
                foreach(uint lock_modifier in lock_modifiers) {
                    display.ungrab_key(binding.keycode, binding.modifiers, window);
                }
                remove_bindings.append(binding);                    
            }
        }
 
        // remove unbinded keys
        foreach(Keybinding binding in remove_bindings) {
            bindings.remove_all(binding);
        }
    }
 
    /**
     * Event filter method needed to fetch X.Events
     */
    public Gdk.FilterReturn event_filter(Gdk.XEvent gdk_xevent, Gdk.Event gdk_event)
    {
        Gdk.FilterReturn filter_return = Gdk.FilterReturn.CONTINUE;
 
        void* pointer = &gdk_xevent;
        X.Event* xevent = (X.Event*) pointer;
 
         if(xevent->type == X.EventType.KeyPress) {
            foreach(Keybinding binding in bindings) {
                // remove NumLock, CapsLock and ScrollLock from key state
                uint event_mods = xevent.xkey.state & ~ (lock_modifiers[7]);
                if(xevent->xkey.keycode == binding.keycode && event_mods == binding.modifiers) {
                    // call all handlers with pressed key and modifiers
                    binding.handler(gdk_event);
                }
            }
         }
 
        return filter_return;
    }
}
 
public static int main (string[] args)
{
    Gtk.init (ref args);
 
    KeybindingManager manager = new KeybindingManager();
    manager.bind("<Ctrl><Alt>V", test);
 
    Gtk.main ();
    return 0;
}

private static void test()
{
    debug("hotkey pressed");
}
