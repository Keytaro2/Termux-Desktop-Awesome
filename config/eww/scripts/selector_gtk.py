import gi
import os
import glob
import subprocess
import cairo
import math

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib

class WallpaperSelector(Gtk.Window):
    def __init__(self, wallpaper_dir):
        super().__init__(title="Wallpaper Selector")
        self.wallpaper_dir = wallpaper_dir
        
        self.cards = []
        self.images = []
        self.current_index = 0

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)

        self.set_decorated(False)
        self.set_default_size(800, 340) 
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_keep_above(True)
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        self.connect("key-press-event", self.on_key_press)
        self.setup_css()

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        main_box.get_style_context().add_class("main-container")
        self.add(main_box)

        self.scroll = Gtk.ScrolledWindow()
        self.scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER)
        self.scroll.set_margin_top(5) 
        self.scroll.set_margin_bottom(5)
        main_box.pack_start(self.scroll, True, True, 0)

        self.fixed_box = Gtk.Fixed()
        self.fixed_box.set_margin_start(10)
        self.fixed_box.set_margin_end(10)
        self.scroll.add(self.fixed_box)

        self.load_wallpapers()

    def setup_css(self):
        css_string = """
        window {
            background-color: transparent;
        }
        .main-container {
            /* Fully transparent background and no borders */
            background-color: transparent; 
            border: none;
        }
        .card {
            background-color: transparent;
        }
        """
        css_bytes = css_string.encode('utf-8')
        provider = Gtk.CssProvider()
        provider.load_from_data(css_bytes)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def load_wallpapers(self):
        images = glob.glob(os.path.join(self.wallpaper_dir, "*.jpg")) + \
                 glob.glob(os.path.join(self.wallpaper_dir, "*.png"))

        self.overlap_spacing = 40 # Adjusts how "thin" the unselected slices appear
        x_offset = 0

        for i, img_path in enumerate(images):
            self.images.append(img_path)

            # Load wider images (landscape format)
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                filename=img_path,
                width=360, 
                height=220, # Strict height to maintain the horizontal line
                preserve_aspect_ratio=False
            )

            event_box = Gtk.EventBox()
            # Wide invisible box so the slanted rectangle doesn't get cut off
            event_box.set_size_request(460, 260) 
            event_box.get_style_context().add_class("card")
            event_box.set_can_focus(True)

            cursor = Gdk.Cursor.new_from_name(Gdk.Display.get_default(), "pointer")
            event_box.connect("realize", lambda widget: widget.get_window().set_cursor(cursor))
            event_box.connect("button-press-event", self.on_card_clicked, i, img_path)
            event_box.connect("draw", self.on_card_draw, pixbuf, i)

            self.fixed_box.put(event_box, x_offset, 0)
            x_offset += self.overlap_spacing 
            
            self.cards.append(event_box)

        if self.images:
            total_width = x_offset + 460
            self.fixed_box.set_size_request(total_width, 260)

        if self.cards:
            self.current_index = 0
            self.cards[self.current_index].get_style_context().add_class("selected")
            self.update_z_orders()
            self.cards[self.current_index].grab_focus()
            GLib.timeout_add(100, self.scroll_to_current)

    def update_z_orders(self):
        if not self.cards: 
            return False

        # Temporarily remove
        for card in self.cards:
            self.fixed_box.remove(card)

        # Stack left
        for i in range(self.current_index):
            self.fixed_box.put(self.cards[i], i * self.overlap_spacing, 0)

        # Stack right
        for i in range(len(self.cards)-1, self.current_index, -1):
            self.fixed_box.put(self.cards[i], i * self.overlap_spacing, 0)

        # The central one goes last (on top)
        self.fixed_box.put(self.cards[self.current_index], self.current_index * self.overlap_spacing, 0)
            
        self.fixed_box.show_all()
        return False

    def draw_rounded_rect(self, cr, x, y, width, height, radius):
        cr.new_sub_path()
        cr.arc(x + width - radius, y + radius, radius, -math.pi/2, 0)
        cr.arc(x + width - radius, y + height - radius, radius, 0, math.pi/2)
        cr.arc(x + radius, y + height - radius, radius, math.pi/2, math.pi)
        cr.arc(x + radius, y + radius, radius, math.pi, 3*math.pi/2)
        cr.close_path()

    def on_card_draw(self, widget, cr, pixbuf, index):
        alloc = widget.get_allocation()
        width = alloc.width
        height = alloc.height

        is_selected = (self.current_index == index)

        cr.save()
        cr.translate(width / 2.0, height / 2.0)

        # Same inclination for all
        angle_rad = math.radians(-15) 
        matrix = cairo.Matrix(1.0, 0.0, math.tan(angle_rad), 1.0, 0.0, 0.0)
        cr.transform(matrix)

        # THE KEY IS HERE! Same scale (1.0) for all.
        # None exceed their height, they maintain a perfect straight line.
        cr.scale(1.0, 1.0)

        pb_width = pixbuf.get_width()
        pb_height = pixbuf.get_height()
        x = -pb_width / 2.0
        y = -pb_height / 2.0

        # Near-straight corners, like in your reference image
        self.draw_rounded_rect(cr, x, y, pb_width, pb_height, 2.0)

        cr.save()
        cr.clip()
        Gdk.cairo_set_source_pixbuf(cr, pixbuf, x, y)
        cr.paint() 
        
        # Shadow effect for those that are NOT selected
        if not is_selected:
            cr.set_source_rgba(0, 0, 0, 0.55) # Darkens the background ones
            cr.paint()
        cr.restore()

        self.draw_rounded_rect(cr, x, y, pb_width, pb_height, 2.0)
        
        if is_selected:
            cr.set_source_rgba(0.478, 0.635, 0.968, 1.0) # Illuminated light blue border
            cr.set_line_width(2.5) 
        else:
            cr.set_source_rgba(0, 0, 0, 0.8) # Very thin dark border to separate
            cr.set_line_width(1.0)
        
        cr.stroke()

        cr.restore()
        return True

    def navigate(self, direction):
        if not self.cards: return
        self.cards[self.current_index].get_style_context().remove_class("selected")
        self.current_index = (self.current_index + direction) % len(self.cards)
        self.cards[self.current_index].get_style_context().add_class("selected")
        
        self.update_z_orders() 
        self.cards[self.current_index].grab_focus()
        self.scroll_to_current()

    def scroll_to_current(self):
        if not self.cards: return False
        
        target_x = self.current_index * self.overlap_spacing
        adj = self.scroll.get_hadjustment()
        vp_width = self.scroll.get_allocated_width()

        # Perfect centering based on our 460 invisible box
        target = target_x - (vp_width - 460) / 2.0
        
        lower = adj.get_lower()
        upper = adj.get_upper() - adj.get_page_size()
        target = max(lower, min(target, upper))

        adj.set_value(target)
        return False

    def apply_wallpaper(self, img_path):
        subprocess.run(["feh", "--bg-fill", img_path])
        print(f"Wallpaper applied: {img_path}")

    def on_card_clicked(self, widget, event, index, img_path):
        self.cards[self.current_index].get_style_context().remove_class("selected")
        self.current_index = index
        widget.get_style_context().add_class("selected")
        
        self.update_z_orders()
        widget.grab_focus()
        self.scroll_to_current()
        self.apply_wallpaper(img_path)

    def on_key_press(self, widget, event):
        key_name = Gdk.keyval_name(event.keyval)
        if key_name in ("Left", "KP_Left"):
            self.navigate(-1)
            return True
        elif key_name in ("Right", "KP_Right"):
            self.navigate(1)
            return True
        elif key_name in ("Return", "KP_Enter"):
            if self.images and 0 <= self.current_index < len(self.images):
                self.apply_wallpaper(self.images[self.current_index])
            return True
        return False

if __name__ == '__main__':
    wall_dir = os.path.expanduser("~/.config/Wallpaper")
    if not os.path.exists(wall_dir):
        print(f"Directory not found: {wall_dir}")
        exit(1)

    win = WallpaperSelector(wall_dir)
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
