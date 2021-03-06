/*
* Copyright (c) 2011-2013 Yorba Foundation
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

// This dialog displays a boolean search configuration.
public class SavedSearchDialog {

    // Conatins a search row, with a type selector and remove button.
    private class SearchRowContainer {
        public signal void remove (SearchRowContainer this_row);
        public signal void changed (SearchRowContainer this_row);

        private Gtk.ComboBoxText type_combo;
        private Gtk.Grid grid;
        private Gtk.Grid align;
        private Gtk.Button remove_button;
        private SearchCondition.SearchType[] search_types;
        private Gee.HashMap<SearchCondition.SearchType, int> search_types_index;

        private SearchRow? my_row = null;

        public SearchRowContainer () {
            setup_gui ();
            set_type (SearchCondition.SearchType.ANY_TEXT);
        }

        public SearchRowContainer.edit_existing (SearchCondition sc) {
            setup_gui ();
            set_type (sc.search_type);
            set_type_combo_box (sc.search_type);
            my_row.populate (sc);
        }

        private void setup_gui () {
            search_types = SearchCondition.SearchType.as_array ();
            search_types_index = new Gee.HashMap<SearchCondition.SearchType, int> ();
            SearchCondition.SearchType.sort_array (ref search_types);

            type_combo = new Gtk.ComboBoxText ();
            for (int i = 0; i < search_types.length; i++) {
                SearchCondition.SearchType st = search_types[i];
                search_types_index.set (st, i);
                type_combo.append_text (st.display_text ());
            }
            set_type_combo_box (SearchCondition.SearchType.ANY_TEXT); // Sets default.
            type_combo.changed.connect (on_type_changed);

            remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.BUTTON);
            remove_button.halign = Gtk.Align.END;
            remove_button.hexpand = true;
            remove_button.tooltip_text = _("Remove rule");
            remove_button.button_press_event.connect (on_removed);

            align = new Gtk.Grid ();

            grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.add (type_combo);
            grid.add (align);
            grid.add (remove_button);
            grid.show_all ();
        }

        private void on_type_changed () {
            set_type (get_search_type ());
            changed (this);
        }

        private void set_type_combo_box (SearchCondition.SearchType st) {
            type_combo.set_active (search_types_index.get (st));
        }

        private void set_type (SearchCondition.SearchType type) {
            if (my_row != null)
                align.remove (my_row.get_widget ());

            switch (type) {
            case SearchCondition.SearchType.ANY_TEXT:
            case SearchCondition.SearchType.EVENT_NAME:
            case SearchCondition.SearchType.FILE_NAME:
            case SearchCondition.SearchType.TAG:
            case SearchCondition.SearchType.COMMENT:
            case SearchCondition.SearchType.TITLE:
                my_row = new SearchRowText (this);
                break;

            case SearchCondition.SearchType.MEDIA_TYPE:
                my_row = new SearchRowMediaType (this);
                break;

            case SearchCondition.SearchType.FLAG_STATE:
                my_row = new SearchRowFlagged (this);
                break;

            case SearchCondition.SearchType.MODIFIED_STATE:
                my_row = new SearchRowModified (this);
                break;

            case SearchCondition.SearchType.DATE:
                my_row = new SearchRowDate (this);
                break;

            default:
                assert (false);
                break;
            }

            align.add (my_row.get_widget ());
        }

        public SearchCondition.SearchType get_search_type () {
            return search_types[type_combo.get_active ()];
        }

        private bool on_removed (Gdk.EventButton event) {
            remove (this);
            return false;
        }

        public void allow_removal (bool allow) {
            remove_button.sensitive = allow;
        }

        public Gtk.Widget get_widget () {
            return grid;
        }

        public SearchCondition get_search_condition () {
            return my_row.get_search_condition ();
        }

        public bool is_complete () {
            return my_row.is_complete ();
        }
    }

    // Represents a row-type.
    private abstract class SearchRow {
        // Returns the GUI widget for this row.
        public abstract Gtk.Widget get_widget ();

        // Returns the search condition for this row.
        public abstract SearchCondition get_search_condition ();

        // Fills out the fields in this row based on an existing search condition (for edit mode.)
        public abstract void populate (SearchCondition sc);

        // Returns true if the row is valid and complete.
        public abstract bool is_complete ();
    }

    private class SearchRowText : SearchRow {
        private Gtk.Box box;
        private Gtk.ComboBoxText text_context;
        private Gtk.Entry entry;

        private SearchRowContainer parent;

        public SearchRowText (SearchRowContainer parent) {
            this.parent = parent;

            // Ordering must correspond with SearchConditionText.Context
            text_context = new Gtk.ComboBoxText ();
            text_context.append_text (_("contains"));
            text_context.append_text (_("is exactly"));
            text_context.append_text (_("starts with"));
            text_context.append_text (_("ends with"));
            text_context.append_text (_("does not contain"));
            text_context.append_text (_("is not set"));
            text_context.set_active (0);
            text_context.changed.connect (on_changed);

            entry = new Gtk.Entry ();
            entry.set_width_chars (25);
            entry.set_activates_default (true);
            entry.changed.connect (on_changed);

            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.pack_start (text_context, false, false, 0);
            box.pack_start (entry, false, false, 0);
            box.show_all ();
        }

        ~SearchRowText () {
            text_context.changed.disconnect (on_changed);
            entry.changed.disconnect (on_changed);
        }

        public override Gtk.Widget get_widget () {
            return box;
        }

        public override SearchCondition get_search_condition () {
            SearchCondition.SearchType type = parent.get_search_type ();
            string text = entry.get_text ();
            SearchConditionText.Context context = get_text_context ();
            SearchConditionText c = new SearchConditionText (type, text, context);
            return c;
        }

        public override void populate (SearchCondition sc) {
            SearchConditionText? text = sc as SearchConditionText;
            assert (text != null);
            text_context.set_active (text.context);
            entry.set_text (text.text);
            on_changed ();
        }

        public override bool is_complete () {
            return entry.text.chomp () != "" || get_text_context () == SearchConditionText.Context.IS_NOT_SET;
        }

        private SearchConditionText.Context get_text_context () {
            return (SearchConditionText.Context) text_context.get_active ();
        }

        private void on_changed () {
            if (get_text_context () == SearchConditionText.Context.IS_NOT_SET) {
                entry.hide ();
            } else {
                entry.show ();
            }

            parent.changed (parent);
        }
    }

    private class SearchRowMediaType : SearchRow {
        private Gtk.Box box;
        private Gtk.ComboBoxText media_context;
        private Gtk.ComboBoxText media_type;

        private SearchRowContainer parent;

        public SearchRowMediaType (SearchRowContainer parent) {
            this.parent = parent;

            // Ordering must correspond with SearchConditionMediaType.Context
            media_context = new Gtk.ComboBoxText ();
            media_context.append_text (_ ("is"));
            media_context.append_text (_ ("is not"));
            media_context.set_active (0);
            media_context.changed.connect (on_changed);

            // Ordering must correspond with SearchConditionMediaType.MediaType
            media_type = new Gtk.ComboBoxText ();
            media_type.append_text (_ ("any photo"));
            media_type.append_text (_ ("a raw photo"));
            media_type.append_text (_ ("a video"));
            media_type.set_active (0);
            media_type.changed.connect (on_changed);

            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.pack_start (media_context, false, false, 0);
            box.pack_start (media_type, false, false, 0);
            box.show_all ();
        }

        ~SearchRowMediaType () {
            media_context.changed.disconnect (on_changed);
            media_type.changed.disconnect (on_changed);
        }

        public override Gtk.Widget get_widget () {
            return box;
        }

        public override SearchCondition get_search_condition () {
            SearchCondition.SearchType search_type = parent.get_search_type ();
            SearchConditionMediaType.Context context = (SearchConditionMediaType.Context) media_context.get_active ();
            SearchConditionMediaType.MediaType type = (SearchConditionMediaType.MediaType) media_type.get_active ();
            SearchConditionMediaType c = new SearchConditionMediaType (search_type, context, type);
            return c;
        }

        public override void populate (SearchCondition sc) {
            SearchConditionMediaType? media = sc as SearchConditionMediaType;
            assert (media != null);
            media_context.set_active (media.context);
            media_type.set_active (media.media_type);
        }

        public override bool is_complete () {
            return true;
        }

        private void on_changed () {
            parent.changed (parent);
        }
    }

    private class SearchRowModified : SearchRow {
        private Gtk.Box box;
        private Gtk.ComboBoxText modified_context;
        private Gtk.ComboBoxText modified_state;

        private SearchRowContainer parent;

        public SearchRowModified (SearchRowContainer parent) {
            this.parent = parent;

            modified_context = new Gtk.ComboBoxText ();
            modified_context.append_text (_ ("has"));
            modified_context.append_text (_ ("has no"));
            modified_context.set_active (0);
            modified_context.changed.connect (on_changed);

            modified_state = new Gtk.ComboBoxText ();
            modified_state.append_text (_ ("modifications"));
            modified_state.append_text (_ ("internal modifications"));
            modified_state.append_text (_ ("external modifications"));
            modified_state.set_active (0);
            modified_state.changed.connect (on_changed);

            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.pack_start (modified_context, false, false, 0);
            box.pack_start (modified_state, false, false, 0);
            box.show_all ();
        }

        ~SearchRowModified () {
            modified_state.changed.disconnect (on_changed);
            modified_context.changed.disconnect (on_changed);
        }

        public override Gtk.Widget get_widget () {
            return box;
        }

        public override SearchCondition get_search_condition () {
            SearchCondition.SearchType search_type = parent.get_search_type ();
            SearchConditionModified.Context context = (SearchConditionModified.Context) modified_context.get_active ();
            SearchConditionModified.State state = (SearchConditionModified.State) modified_state.get_active ();
            SearchConditionModified c = new SearchConditionModified (search_type, context, state);
            return c;
        }

        public override void populate (SearchCondition sc) {
            SearchConditionModified? scm = sc as SearchConditionModified;
            assert (scm != null);
            modified_state.set_active (scm.state);
            modified_context.set_active (scm.context);
        }

        public override bool is_complete () {
            return true;
        }

        private void on_changed () {
            parent.changed (parent);
        }
    }

    private class SearchRowFlagged : SearchRow {
        private Gtk.Box box;
        private Gtk.ComboBoxText flagged_state;

        private SearchRowContainer parent;

        public SearchRowFlagged (SearchRowContainer parent) {
            this.parent = parent;

            // Ordering must correspond with SearchConditionFlagged.State
            flagged_state = new Gtk.ComboBoxText ();
            flagged_state.append_text (_ ("flagged"));
            flagged_state.append_text (_ ("not flagged"));
            flagged_state.set_active (0);
            flagged_state.changed.connect (on_changed);

            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.pack_start (new Gtk.Label (_ ("is")), false, false, 0);
            box.pack_start (flagged_state, false, false, 0);
            box.show_all ();
        }

        ~SearchRowFlagged () {
            flagged_state.changed.disconnect (on_changed);
        }

        public override Gtk.Widget get_widget () {
            return box;
        }

        public override SearchCondition get_search_condition () {
            SearchCondition.SearchType search_type = parent.get_search_type ();
            SearchConditionFlagged.State state = (SearchConditionFlagged.State) flagged_state.get_active ();
            SearchConditionFlagged c = new SearchConditionFlagged (search_type, state);
            return c;
        }

        public override void populate (SearchCondition sc) {
            SearchConditionFlagged? f = sc as SearchConditionFlagged;
            assert (f != null);
            flagged_state.set_active (f.state);
        }

        public override bool is_complete () {
            return true;
        }

        private void on_changed () {
            parent.changed (parent);
        }
    }

    private class SearchRowDate : SearchRow {
        private const string DATE_FORMAT = "%x";
        private Gtk.Box box;
        private Gtk.ComboBoxText context;
        private Granite.Widgets.DatePicker datepicker_one;
        private Granite.Widgets.DatePicker datepicker_two;
        private Gtk.Label and;

        private SearchRowContainer parent;

        public SearchRowDate (SearchRowContainer parent) {
            this.parent = parent;

            // Ordering must correspond with Context
            context = new Gtk.ComboBoxText ();
            context.append_text (_("is exactly"));
            context.append_text (_("is after"));
            context.append_text (_("is before"));
            context.append_text (_("is between"));
            context.append_text (_("is not set"));
            context.set_active (0);
            context.changed.connect (on_changed);

            datepicker_one = new Granite.Widgets.DatePicker ();
            datepicker_two = new Granite.Widgets.DatePicker ();

            and = new Gtk.Label (_ ("and"));

            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.pack_start (context, false, false, 0);
            box.pack_start (datepicker_one, false, false, 0);
            box.pack_start ( and , false, false, 0);
            box.pack_start (datepicker_two, false, false, 0);

            box.show_all ();
            update_datepickers ();
        }

        ~SearchRowDate () {
            context.changed.disconnect (on_changed);
        }

        private void update_datepickers () {
            SearchConditionDate.Context c = (SearchConditionDate.Context)context.get_active ();

            // Only show "and" and 2nd date label for between mode.
            if (c == SearchConditionDate.Context.BETWEEN) {
                datepicker_one.show ();
                and.show ();
                datepicker_two.show ();
            } else if (c == SearchConditionDate.Context.IS_NOT_SET) {
                datepicker_one.hide ();
                and.hide ();
                datepicker_two.hide ();
            } else {
                datepicker_one.show ();
                and.hide ();
                datepicker_two.hide ();
            }
        }

        public override Gtk.Widget get_widget () {
            return box;
        }

        public override SearchCondition get_search_condition () {
            SearchCondition.SearchType search_type = parent.get_search_type ();
            SearchConditionDate.Context search_context = (SearchConditionDate.Context) context.get_active ();
            SearchConditionDate c = new SearchConditionDate (search_type, search_context, datepicker_one.date,
                    datepicker_two.date);
            return c;
        }

        public override void populate (SearchCondition sc) {
            SearchConditionDate? cond = sc as SearchConditionDate;
            assert (cond != null);
            context.set_active (cond.context);
            datepicker_one.date = cond.date_one;
            datepicker_two.date = cond.date_two;
            update_datepickers ();
        }

        public override bool is_complete () {
            return true;
        }

        private void on_changed () {
            parent.changed (parent);
            update_datepickers ();
        }
    }

    private Gtk.Dialog dialog;
    private Gtk.Button add_criteria;
    private Gtk.ComboBoxText operator;
    private Gtk.Grid row_box;
    private Gtk.Entry search_title;
    private Gee.ArrayList<SearchRowContainer> row_list = new Gee.ArrayList<SearchRowContainer> ();
    private bool edit_mode = false;
    private SavedSearch? previous_search = null;
    private bool valid = false;

    public SavedSearchDialog () {
        setup_dialog ();

        // Default name.
        search_title.set_text (SavedSearchTable.get_instance ().generate_unique_name ());
        search_title.select_region (0, -1); // select all

        // Default is text search.
        add_text_search ();
        row_list.get (0).allow_removal (false);

        // Add buttons for new search.
        dialog.add_action_widget (new Gtk.Button.with_label (_ ("Cancel")), Gtk.ResponseType.CANCEL);
        Gtk.Button ok_button = new Gtk.Button.with_label (_ ("Add"));
        ok_button.can_default = true;
        dialog.add_action_widget (ok_button, Gtk.ResponseType.OK);
        dialog.set_default_response (Gtk.ResponseType.OK);

        dialog.show_all ();
        set_valid (false);
    }

    public SavedSearchDialog.edit_existing (SavedSearch saved_search) {
        previous_search = saved_search;
        edit_mode = true;
        setup_dialog ();

        // Add close button.
        Gtk.Button close_button = new Gtk.Button.with_label (_ ("Save"));
        close_button.can_default = true;
        dialog.add_action_widget (close_button, Gtk.ResponseType.OK);
        dialog.set_default_response (Gtk.ResponseType.OK);

        dialog.show_all ();

        // Load existing search into dialog.
        operator.set_active ((SearchOperator) saved_search.get_operator ());
        search_title.set_text (saved_search.get_name ());
        foreach (SearchCondition sc in saved_search.get_conditions ()) {
            add_row (new SearchRowContainer.edit_existing (sc));
        }

        if (row_list.size == 1)
            row_list.get (0).allow_removal (false);

        set_valid (true);
    }

    ~SavedSearchDialog () {
        search_title.changed.disconnect (on_title_changed);
    }

    // Builds the dialog UI.  Doesn't add buttons to the dialog or call dialog.show ().
    private void setup_dialog () {
        dialog = new Gtk.Dialog ();
        dialog.title = _ ("Smart Album");
        dialog.modal = true;
        dialog.transient_for = AppWindow.get_instance ();
        dialog.response.connect (on_response);
        dialog.deletable = false;

        add_criteria = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON);
        add_criteria.button_press_event.connect (on_add_criteria);

        Gtk.Label search_label = new Gtk.Label ("Name:");

        search_title = new Gtk.Entry ();
        search_title.activates_default = true;
        search_title.hexpand = true;
        search_title.changed.connect (on_title_changed);

        Gtk.Grid search_content_grid = new Gtk.Grid ();
        search_content_grid.orientation = Gtk.Orientation.HORIZONTAL;
        search_content_grid.column_spacing = 6;
        search_content_grid.add (search_label);
        search_content_grid.add (search_title);

        Gtk.Label match_label = new Gtk.Label.with_mnemonic (_ ("_Match"));
        Gtk.Label match2_label = new Gtk.Label.with_mnemonic (_ ("of the following:"));
        match2_label.hexpand = true;
        ((Gtk.Misc) match2_label).xalign = 0.0f;

        row_box = new Gtk.Grid ();
        row_box.orientation = Gtk.Orientation.VERTICAL;
        row_box.row_spacing = 12;

        operator = new Gtk.ComboBoxText ();
        operator.append_text (_ ("any"));
        operator.append_text (_ ("all"));
        operator.append_text (_ ("none"));
        operator.active = 0;

        Gtk.Grid match_grid = new Gtk.Grid ();
        match_grid.orientation = Gtk.Orientation.HORIZONTAL;
        match_grid.column_spacing = 6;
        match_grid.add (match_label);
        match_grid.add (operator);
        match_grid.add (match2_label);
        match_grid.add (add_criteria);

        Gtk.Grid search_grid = new Gtk.Grid ();
        search_grid.orientation = Gtk.Orientation.VERTICAL;
        search_grid.margin = 12;
        search_grid.row_spacing = 12;

        search_grid.add (search_content_grid);
        search_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        search_grid.add (match_grid);
        search_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        search_grid.add (row_box);

        Gtk.Box content = dialog.get_content_area () as Gtk.Box;
        content.add (search_grid);
    }

    // Displays the dialog.
    public void show () {
        dialog.run ();
        dialog.destroy ();
    }

    // Adds a row of search criteria.
    private bool on_add_criteria (Gdk.EventButton event) {
        add_text_search ();
        return false;
    }

    private void add_text_search () {
        SearchRowContainer text = new SearchRowContainer ();
        add_row (text);
    }

    // Appends a row of search criteria to the list and table.
    private void add_row (SearchRowContainer row) {
        if (row_list.size == 1)
            row_list.get (0).allow_removal (true);
        row_box.add (row.get_widget ());
        row_list.add (row);
        row.remove.connect (on_remove_row);
        row.changed.connect (on_row_changed);
        set_valid (row.is_complete ());
    }

    // Removes a row of search criteria.
    private void on_remove_row (SearchRowContainer row) {
        row.remove.disconnect (on_remove_row);
        row.changed.disconnect (on_row_changed);
        row_box.remove (row.get_widget ());
        row_list.remove (row);
        if (row_list.size == 1)
            row_list.get (0).allow_removal (false);
        set_valid (true); // try setting to "true" since we removed a row
    }

    private void on_response (int response_id) {
        if (response_id == Gtk.ResponseType.OK) {
            if (SavedSearchTable.get_instance ().exists (search_title.get_text ()) &&
                    ! (edit_mode && previous_search.get_name () == search_title.get_text ())) {
                AppWindow.error_message (Resources.rename_search_exists_message (search_title.get_text ()));
                return;
            }

            if (edit_mode) {
                // Remove previous search.
                SavedSearchTable.get_instance ().remove (previous_search);
            }

            // Build the condition list from the search rows, and add our new saved search to the table.
            Gee.ArrayList<SearchCondition> conditions = new Gee.ArrayList<SearchCondition> ();
            foreach (SearchRowContainer c in row_list) {
                conditions.add (c.get_search_condition ());
            }

            // Create the object.  It will be added to the DB and SearchTable automatically.
            SearchOperator search_operator = (SearchOperator)operator.get_active ();
            SavedSearchTable.get_instance ().create (search_title.get_text (), search_operator, conditions);
        }
    }

    private void on_row_changed (SearchRowContainer row) {
        set_valid (row.is_complete ());
    }

    private void on_title_changed () {
        set_valid (is_title_valid ());
    }

    private bool is_title_valid () {
        if (edit_mode && previous_search != null &&
                previous_search.get_name () == search_title.get_text ())
            return true; // Title hasn't changed.
        if (search_title.get_text ().chomp () == "")
            return false;
        if (SavedSearchTable.get_instance ().exists (search_title.get_text ()))
            return false;
        return true;
    }

    // Call this with your new value for validity whenever a row or the title changes.
    private void set_valid (bool v) {
        if (!v) {
            valid = false;
        } else if (v != valid) {
            if (is_title_valid ()) {
                // Go through rows to check validity.
                int valid_rows = 0;
                foreach (SearchRowContainer c in row_list) {
                    if (c.is_complete ())
                        valid_rows++;
                }
                valid = (valid_rows == row_list.size);
            } else {
                valid = false; // title was invalid
            }
        }

        dialog.set_response_sensitive (Gtk.ResponseType.OK, valid);
    }
}
