// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE
	
  Copyright (C) 2011 Giulio Collura <random.cpp@gmail.com>
  This program is free software: you can redistribute it and/or modify it	
  under the terms of the GNU Lesser General Public License version 3, as published	
  by the Free Software Foundation.
	
  This program is distributed in the hope that it will be useful, but	
  WITHOUT ANY WARRANTY; without even the implied warranties of	
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR	
  PURPOSE.  See the GNU General Public License for more details.
	
  You should have received a copy of the GNU General Public License along	
  with this program.  If not, see <http://www.gnu.org/licenses/>	
  
  END LICENSE	
***/

using GtkSource;
using Scratch.Widgets;

namespace Scratch.Services {

    public enum DocumentStates {

        NORMAL,
        READONLY

    }

    public class Document : GLib.Object {
        
        // Signals
        public signal void opened ();
        public signal void closed ();
        
        // Public properties
        public bool saved { 
            get {
                if (original_text == text)
                    return true;
                else
                    return false;
            }
        }
        private string? _name;
        public string? name {
            get {
                return _name;
            }
        }
        
        private string _directory;
        public string directory {
            get {
                return _directory;
            }
        }

        public Language language {
            get {
                var manager = new LanguageManager ();
                return manager.guess_language (filename, null);
            }
        }

        public string filename      { get; private set; }
        public string text          { get; set; }
        public DocumentStates state {
            get {
                if (can_write ())
                    return DocumentStates.NORMAL;
                else
                    return DocumentStates.READONLY;
            }
        }

        public bool exists {
            get {
                if (filename != null)
                    return FileUtils.test (filename, FileTest.EXISTS);
                else
                    return false;
            }
        }
        
        // Private variables
        private string original_text;
        private Buffer buffer;
        private MainWindow window;
        private File file;
        private static string home_dir = Environment.get_home_dir ();
        Tab tab;

        public Document (string filename, MainWindow? window) {

            
            this.filename = filename;
            file = File.new_for_path (filename);
            
            _name = file.get_basename ();
            _directory = Path.get_dirname (filename).replace (home_dir, "~");

            this.window = window;
            
        }
        
        /**
         * In this function, we create a new tab and we load the content of the file in it. 
         **/
        public void create_sourceview ()
        {
			//get the filename from strig filename =)
			var name = Filename.display_basename (filename);
		

			//create new tab
			int tab_index = window.current_notebook.add_tab (name);
			window.current_notebook.set_current_page (tab_index);                        
			tab = (Tab) window.current_notebook.get_nth_page (tab_index);
              
			//set new values
			tab.filename = filename;
			tab.saved = true;
            
			buffer = tab.text_view.buffer;
			tab.text_view.change_syntax_highlight_for_filename(filename);
			
			open();
        }

        public Document.empty (MainWindow? window) {
            
            filename = null;
            this.window = window;

        }

		/**
		 * Open the file and put it content inside the given buffer.
		 **/
        public bool open () throws FileError {

            if (filename == null)
                return false;

            bool result;
            string contents;
			try {
				FileUtils.get_contents (filename, out contents);
			} catch (Error e) {
				window.infobar.set_info (_("The file could not be opened"));
				return false;
			}
            original_text = text = contents;
		
			if(!contents.validate()) contents = convert (contents, -1, "UTF-8", "ISO-8859-1");

            if (buffer != null) {
                buffer.begin_not_undoable_action ();
            	buffer.text = this.text;
                buffer.end_not_undoable_action ();
            }
            else
            	warning ("No buffer selected.");
            
            /* TODO: real encoding detection */
            
            this.opened (); // Signal

            return true;

        }

        public bool close () {

            if (!saved)
                return false;

            this.closed (); // Signal
            return true;

        }

        public bool save () throws FileError {
            
            // TODO: need smart implementation
            return false;

        }

        public void update () {

        }

        public bool rename (string new_name) {

            FileUtils.rename (filename, new_name);
            filename = new_name;
            return true;

        }

        public uint64 get_mtime () {
            
            try {
                var info = file.query_info (FILE_ATTRIBUTE_TIME_MODIFIED, 0, null);
                return info.get_attribute_uint64 (FILE_ATTRIBUTE_TIME_MODIFIED);
            } catch  (Error e) {
                warning ("%s", e.message);
                return 0;
            }
        
        }

        public string get_mime_type () {

            if (filename == null)
                return "text/plain";
            else {
                FileInfo info;
                string mime_type;
                try {
                    info = file.query_info ("standard::*", FileQueryInfoFlags.NONE, null);
                    mime_type = ContentType.get_mime_type (info.get_content_type ());
                    return mime_type;
                } catch (Error e) {
                    warning ("%s", e.message);
                    return "undefined";
                }
            }

        
        }

        public int64 get_size () {

            if (filename != null) {

                FileInfo info;
                int64 size;
                try {
                    info = file.query_info (FILE_ATTRIBUTE_STANDARD_SIZE, FileQueryInfoFlags.NONE, null);
                    size = info.get_size ();
                    return size;
                } catch (Error e) {
                    warning ("%s", e.message);
                    return 0;
                }

            } else {

                return 0;

            }

        }

        private bool can_write () {

            if (filename != null) {

                FileInfo info;
                bool writable;
                try {
                    info = file.query_info (FILE_ATTRIBUTE_ACCESS_CAN_WRITE, FileQueryInfoFlags.NONE, null);
                    writable = info.get_attribute_boolean (FILE_ATTRIBUTE_ACCESS_CAN_WRITE);
                    return writable;
                } catch (Error e) {
                    warning ("%s", e.message);
                    return false;
                }

            } else {

                return true;

            }

        }

    }

}
