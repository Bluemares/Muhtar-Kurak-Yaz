import tempfile
import unittest
import zipfile
from pathlib import Path
from package import package


class PackageTests(unittest.TestCase):
    def test_only_current_game_and_no_personal_files(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            windows = root / 'build/windows'
            web = root / 'build/web'
            windows.mkdir(parents=True)
            web.mkdir()
            for name, data in {'MuhtarKurakYaz-Guncel.exe': b'new',
                               'MuhtarKurakYaz.exe': b'old',
                               'MuhtarKurakYaz.tmp': b'temporary',
                               'savegame.json': b'private',
                               'settings.cfg': b'private'}.items():
                (windows / name).write_bytes(data)
            (web / 'index.html').write_text('game', encoding='utf-8')
            package(root)
            with zipfile.ZipFile(root / 'build/MuhtarKurakYaz_windows.zip') as z:
                self.assertEqual(z.namelist(), ['MuhtarKurakYaz.exe'])
                self.assertEqual(z.read('MuhtarKurakYaz.exe'), b'new')


if __name__ == '__main__':
    unittest.main()
