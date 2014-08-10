/* Copyright 2011-2013 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Library.LastImportSidebarEntry : Library.HideablePageEntry {
    public LastImportSidebarEntry () {
        foreach (MediaSourceCollection media_sources in MediaCollectionRegistry.get_instance ().get_all ())
            media_sources.import_roll_altered.connect (on_import_rolls_altered);

        visible = (MediaCollectionRegistry.get_instance ().get_last_import_id () != null);
    }

    ~LastImportSidebarEntry () {
        foreach (MediaSourceCollection media_sources in MediaCollectionRegistry.get_instance ().get_all ())
            media_sources.import_roll_altered.disconnect (on_import_rolls_altered);
    }

    public override string get_sidebar_name () {
        return LastImportPage.NAME;
    }

    public override Icon? get_sidebar_icon () {
        return new ThemedIcon (Resources.ICON_LAST_IMPORT);
    }

    protected override Page create_page () {
        return new LastImportPage ();
    }

    private void on_import_rolls_altered () {
        visible = (MediaCollectionRegistry.get_instance ().get_last_import_id () != null);
    }
}

