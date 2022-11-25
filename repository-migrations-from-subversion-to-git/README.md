# 将资料库从 Subversion(SVN) 迁移到 Git

本文介绍 Windows 下如何将 Subversion(SVN) 资料库内容迁移到 git 仓库。

> 注意：下述命令行是在 `Git Bash` 环境中执行的。

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

如果想将导入后的代码推送到远端 git 仓库，比如 github 上的 `new-repo` 则可以执行：

```shell
cd /d/git-wk/my-repo
git checkout svn

git remote add origin https://github.com/the-account/new-repo.git
git push -u origin refs/heads/master:refs/heads/master
```

> 注意：github 上的 new-repo 仓库必须预先存在。最好是新创建的空仓库，如果 new-repo 里原本就有代码会无法推送，因为远端和本地代码没有基版本关联信息，是无法推送的。
