# 将资料库从 Subversion(SVN) 迁移到 Git

本文介绍 Windows 下如何将 Subversion(SVN) 资料库内容迁移到 git 仓库。

> 注意：下述命令行是在 `Git Bash` 环境中执行的。

## 迁移前检查

迁移前建议先确认：

- SVN 仓库采用的布局是否为 `trunk`、`branches`、`tags` 的标准布局；非标准布局需要调整 `git svn clone` 参数。
- SVN 仓库当前版本号和提交记录是否可以正常读取。
- 迁移执行机器是否有足够磁盘空间保存 SVN 工作副本和 Git 仓库。
- 目标 Git 仓库应为空仓库，且不要在迁移验证完成前提供给团队正式使用。
- 迁移只是生成新的 Git 历史，原 SVN 仓库应先保留，不要立即删除或停用。

如果仓库在本地目录，如 `d:\svn-repos\my-repo`，可以用 svn 自带的 `svnserve` 程序在本地架设 svn 服务。

```shell
svnserve -d -r /d/svn-repos
```

然后就可以用 `svn://localhost/my-repo` 访问仓库了。

如果 svn 仓库在远端就直接使用远端地址。

> 注意：不要直接使用 `file:///d:/svn-repos/my-repo` 访问本地仓库，直接用 `file://` 时后面的 `git svn` 命令会报错。

签出 svn 工作目录，导出 svn 提交者信息。

```cmd
mkdir /d/svn-wk
cd /d/svn-wk
svn checkout svn://localhost/my-repo
cd my-repo
# 导出 svn 提交者信息到 authors.txt 文件
svn log -q | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | LC_ALL=C sort -u > authors.txt
```

authors.txt 的内容看起来大概是这样。

```plain
张三 = zhangsan <zhangsan@mail.com>
lisi = lisi <lisi@mail.com>
```

如果想在导入 git 后保留这些原始信息，就不要改动 authors.txt 的内容。

如果想把 `张三` 和 git 账户 `88888888+zhang-san@users.noreply.github.com` 绑定，则可以修改相应行等号右边的部分，如：

```plain
张三 = zhang-san <88888888+zhang-san@users.noreply.github.com>
lisi = lisi <lisi@mail.com>
```

> 注意：有时候 svn 输出的 authors.txt 可能有乱码，可以在这个时候修正过来。方法同样是将等号右边部分修改成想要的名字和邮件地址，等号左边即便有乱码也要保留不动。

接下来用 `git svn` 命令创建本地 git 仓库并将 svn 仓库内容导入。`git svn` 命令参数含义可以参考官方文档：https://git-scm.com/docs/git-svn

```shell
mkdir /d/git-wk
cd /d/git-wk
git svn clone --stdlayout --authors-file=/d/svn-wk/my-repo/authors.txt svn://localhost/my-repo
```

clone 成功后会形成一个新的 git 本地工作目录，其中有个名为 `svn` 的分支，其内容即为导入后的代码。

```shell
cd /d/git-wk/my-repo
git branch --list
```

## 校验迁移结果

推送前先在本地检查迁移结果：

```shell
cd /d/git-wk/my-repo

# 查看最新提交信息、作者和日期
git log --decorate --date=iso -n 10

# 检查提交数量是否合理
git rev-list --count HEAD

# 检查导出的分支和标签
git branch -a
git tag -l

# 检查关键目录和文件是否存在
git ls-tree -r --name-only HEAD | less
```

如果项目有可构建的基线版本，应在本地检出迁移结果后执行构建和测试，确认源码内容没有缺失。

## 失败处理和回滚

常见的处理原则如下：

- `git svn clone` 中断后，可进入已生成的 Git 仓库执行 `git svn fetch` 继续拉取。
- 作者映射缺失时，应根据报错补充 `authors.txt` 后重新迁移，或按 `git svn` 文档使用作者兜底配置。
- 迁移结果校验失败时，优先删除本次生成的 `/d/git-wk/my-repo` 并重新执行 `git svn clone`。
- 在确认迁移结果正确前，不要执行 `git push`。
- 如果错误提交已经推送到空远端仓库，且确认没有其他人使用，可以删除远端仓库后重建；不要习惯性使用强制推送覆盖他人工作。

如果想将导入后的代码推送到远端 git 仓库，比如 github 上的 `new-repo` 则可以执行：

```shell
cd /d/git-wk/my-repo
git checkout svn

git remote add origin https://github.com/the-account/new-repo.git
git push -u origin refs/heads/master:refs/heads/master
```

> 注意：github 上的 new-repo 仓库必须预先存在。最好是新创建的空仓库，如果 new-repo 里原本就有代码会无法推送，因为远端和本地代码没有基版本关联信息，是无法推送的。
