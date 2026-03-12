import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';

const DOMAIN = 0x0000;
const DB_NAME = 'plantdiary.db';
const BACKUP_DB_NAME = 'plantdiary_backup.db';
const PHOTOS_DIR = 'photos';

export default class EntryBackupAbility extends BackupExtensionAbility {
  private getContext(): common.Context {
    return this.context as common.Context;
  }

  private getDbPath(): string {
    return this.getContext().databaseDir + '/' + DB_NAME;
  }

  private getBackupDbPath(): string {
    return this.getContext().filesDir + '/' + BACKUP_DB_NAME;
  }

  private getPhotosPath(): string {
    return this.getContext().filesDir + '/' + PHOTOS_DIR;
  }

  private async copyFile(src: string, dest: string): Promise<void> {
    try {
      const srcFile = fs.openSync(src, fs.OpenMode.READ_ONLY);
      const destFile = fs.openSync(dest, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      
      const stat = fs.statSync(src);
      const buffer = new ArrayBuffer(8192);
      let offset = 0;
      
      while (offset < stat.size) {
        const bytesRead = fs.readSync(srcFile.fd, buffer, { offset: 0, length: Math.min(8192, stat.size - offset) });
        if (bytesRead === 0) break;
        fs.writeSync(destFile.fd, buffer, { offset: 0, length: bytesRead });
        offset += bytesRead;
      }
      
      fs.closeSync(srcFile);
      fs.closeSync(destFile);
      hilog.info(DOMAIN, 'Backup', 'File copied: %{public}s -> %{public}s', src, dest);
    } catch (err) {
      hilog.error(DOMAIN, 'Backup', 'Copy file failed: %{public}s', JSON.stringify(err));
      // throw err;
    }
  }

  private async copyDirectory(src: string, dest: string): Promise<void> {
    try {
      if (!fs.accessSync(dest)) {
        fs.mkdirSync(dest);
      }
      
      const files = fs.listFileSync(src);
      for (const file of files) {
        const srcPath = src + '/' + file;
        const destPath = dest + '/' + file;
        const stat = fs.statSync(srcPath);
        
        if (stat.isDirectory()) {
          await this.copyDirectory(srcPath, destPath);
        } else {
          await this.copyFile(srcPath, destPath);
        }
      }
      hilog.info(DOMAIN, 'Backup', 'Directory copied: %{public}s -> %{public}s', src, dest);
    } catch (err) {
      hilog.error(DOMAIN, 'Backup', 'Copy directory failed: %{public}s', JSON.stringify(err));
      // throw err;
    }
  }

  private async deleteDirectory(dir: string): Promise<void> {
    try {
      if (!fs.accessSync(dir)) {
        return;
      }
      
      const files = fs.listFileSync(dir);
      for (const file of files) {
        const filePath = dir + '/' + file;
        const stat = fs.statSync(filePath);
        
        if (stat.isDirectory()) {
          await this.deleteDirectory(filePath);
        } else {
          fs.unlinkSync(filePath);
        }
      }
      fs.rmdirSync(dir);
      hilog.info(DOMAIN, 'Backup', 'Directory deleted: %{public}s', dir);
    } catch (err) {
      hilog.error(DOMAIN, 'Backup', 'Delete directory failed: %{public}s', JSON.stringify(err));
    }
  }

  async onBackup() {
    hilog.info(DOMAIN, 'Backup', 'onBackup started');
    try {
      const ctx = this.getContext();
      
      if (!fs.accessSync(ctx.filesDir)) {
        fs.mkdirSync(ctx.filesDir);
      }

      const dbPath = this.getDbPath();
      if (fs.accessSync(dbPath)) {
        await this.copyFile(dbPath, this.getBackupDbPath());
        hilog.info(DOMAIN, 'Backup', 'Database backup successful');
      } else {
        hilog.warn(DOMAIN, 'Backup', 'Database file not found, skipping');
      }

      const photosPath = this.getPhotosPath();
      if (fs.accessSync(photosPath)) {
        const backupPhotosPath = ctx.filesDir + '/' + PHOTOS_DIR + '_backup';
        await this.deleteDirectory(backupPhotosPath);
        await this.copyDirectory(photosPath, backupPhotosPath);
        hilog.info(DOMAIN, 'Backup', 'Photos backup successful');
      } else {
        hilog.warn(DOMAIN, 'Backup', 'Photos directory not found, skipping');
      }

      hilog.info(DOMAIN, 'Backup', 'onBackup completed successfully');
    } catch (err) {
      hilog.error(DOMAIN, 'Backup', 'onBackup failed: %{public}s', JSON.stringify(err));
      // throw err;
    }
  }

  async onRestore(bundleVersion: BundleVersion) {
    hilog.info(DOMAIN, 'Backup', 'onRestore started, bundleVersion: %{public}s', JSON.stringify(bundleVersion));
    try {
      const ctx = this.getContext();

      const backupDbPath = this.getBackupDbPath();
      if (fs.accessSync(backupDbPath)) {
        await this.copyFile(backupDbPath, this.getDbPath());
        hilog.info(DOMAIN, 'Backup', 'Database restore successful');
      } else {
        hilog.warn(DOMAIN, 'Backup', 'Backup database not found, skipping');
      }

      const backupPhotosPath = ctx.filesDir + '/' + PHOTOS_DIR + '_backup';
      if (fs.accessSync(backupPhotosPath)) {
        const photosPath = this.getPhotosPath();
        await this.deleteDirectory(photosPath);
        await this.copyDirectory(backupPhotosPath, photosPath);
        hilog.info(DOMAIN, 'Backup', 'Photos restore successful');
      } else {
        hilog.warn(DOMAIN, 'Backup', 'Backup photos not found, skipping');
      }

      hilog.info(DOMAIN, 'Backup', 'onRestore completed successfully');
    } catch (err) {
      hilog.error(DOMAIN, 'Backup', 'onRestore failed: %{public}s', JSON.stringify(err));
      // throw err;
    }
  }
}