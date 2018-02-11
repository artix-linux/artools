def ADD_REPO = ''
def RM_REPO = ''
def IS_ADD = 'false'
def IS_REMOVE = 'false'
def IS_BUILD = 'false'
def PKG_TRUNK = ''
def PKG_PATH = ''

pipeline {
    agent any
    options {
        skipDefaultCheckout()
        timestamps()
    }
    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout scm

                    def currentCommit = sh(returnStdout: true, script: 'git rev-parse @').trim()
                    echo "currentCommit: ${currentCommit}"

                    def changedFilesStatus = sh(returnStdout: true, script: "git show --pretty=format: --name-status ${currentCommit}").tokenize('\n')
                    def changedPkgStatus = []
                    def pkgPath = []
                    int entryCount = 0
                    for ( int i = 0; i < changedFilesStatus.size(); i++ ) {
                        def entry = changedFilesStatus[i].split()
                        def fileStatus = entry[0]
                        entryCount = entry.size()
                        for ( int j = 1; j < entry.size(); j++ ) {
                            if ( entry[j].contains('/PKGBUILD') && entry[j].contains('/repos') ){
                                changedPkgStatus << "${fileStatus} " + entry[j].minus('/PKGBUILD')
                                pkgPath << entry[j].minus('/PKGBUILD')
                            }
                        }
                    }

                    int pkgCount = changedPkgStatus.size()
                    int pkgPathCount = pkgPath.size()
                    echo "pkgCount: ${pkgCount}"
                    echo "entryCount: ${entryCount}"
                    echo "pkgPathCount: ${pkgPathCount}"
                    echo "changedPkgStatus: ${changedPkgStatus}"

                    if ( pkgCount > 0 ) {

                        if ( entryCount == 2 && pkgCount == 2 ) {
                            def pkgEntry1 = changedPkgStatus[0].split()
                            def pkgEntry2 = changedPkgStatus[1].split()
                            def srcPath = []
                            def pkgStatus = []
                            srcPath << pkgEntry1[1]
                            srcPath << pkgEntry2[1]
                            pkgStatus << pkgEntry1[0]
                            pkgStatus << pkgEntry2[0]
                            def buildInfo1 = srcPath[0].tokenize('/')
                            def buildInfo2 = srcPath[1].tokenize('/')

                            if ( pkgStatus[0] == "M" ) {
                                IS_ADD = 'true'
                                if ( srcPath[0].contains('community-testing') ) {
                                    ADD_REPO = 'galaxy-gremlins'
                                } else if ( srcPath[0].contains('community-x86_64') || srcPath[0].contains('community-any') ) {
                                    ADD_REPO = 'galaxy'
                                }
                                if ( srcPath[0].contains('multilib-testing') ) {
                                    ADD_REPO = 'lib32-gremlins'
                                } else if ( srcPath[0].contains('multilib-x86_64') ) {
                                    ADD_REPO = 'lib32'
                                }
                            } else if ( pkgStatus[1] == "M" ) {
                                IS_ADD = 'true'
                                if ( srcPath[1].contains('community-testing') ) {
                                    ADD_REPO = 'galaxy-gremlins'
                                } else if ( srcPath[1].contains('community-x86_64') || srcPath[1].contains('community-any') ) {
                                    ADD_REPO = 'galaxy'
                                }
                                if ( srcPath[1].contains('multilib-testing') ) {
                                    ADD_REPO = 'lib32-gremlins'
                                } else if ( srcPath[1].contains('multilib-x86_64') ) {
                                    ADD_REPO = 'lib32'
                                }
                            }

                            if ( pkgStatus[0] == "D" ) {
                                IS_REMOVE = 'true'
                                if ( srcPath[0].contains('community-testing') ) {
                                    RM_REPO = 'galaxy-gremlins'
                                } else if ( srcPath[0].contains('community-x86_64') || srcPath[0].contains('community-any') ) {
                                    RM_REPO = 'galaxy'
                                }
                                if ( srcPath[0].contains('multilib-testing') ) {
                                    RM_REPO = 'lib32-gremlins'
                                } else if ( srcPath[0].contains('multilib-x86_64') ) {
                                    RM_REPO = 'lib32'
                                }
                            } else if ( pkgStatus[1] == "D" ) {
                                IS_REMOVE = 'true'
                                if ( srcPath[1].contains('community-testing') ) {
                                    RM_REPO = 'galaxy-gremlins'
                                } else if ( srcPath[1].contains('community-x86_64') || srcPath[1].contains('community-any') ) {
                                    RM_REPO = 'galaxy'
                                }
                                if ( srcPath[1].contains('multilib-testing') ) {
                                    RM_REPO = 'lib32-gremlins'
                                } else if ( srcPath[1].contains('multilib-x86_64') ) {
                                    RM_REPO = 'lib32'
                                }
                            }



                            PKG_TRUNK = buildInfo1[0] + '/trunk'
                        }

                        if ( entryCount == 3 && pkgCount == 2 ) {
                            def pkgEntry = changedPkgStatus[0].split()
                            def pkgStatus = pkgEntry[0]
                            def buildInfo1 = pkgPath[0].tokenize('/')
                            def buildInfo2 = pkgPath[1].tokenize('/')

                            if ( pkgStatus.contains('R') ) {
                                IS_ADD = 'true'
                                IS_REMOVE = 'true'

                                if ( pkgPath[0].contains('community-staging') && pkgPath[1].contains('community-testing') ) {
                                    ADD_REPO = 'galaxy-gremlins'
                                    RM_REPO = 'galaxy-goblins'
                                } else if ( pkgPath[0].contains('community-testing') && pkgPath[1].contains('community-staging') ) {
                                    ADD_REPO = 'galaxy-goblins'
                                    RM_REPO = 'galaxy-gremlins'
                                }

                                if ( pkgPath[0].contains('community-testing') && pkgPath[1].contains('community-x86_64') || pkgPath[0].contains('community-any') ) {
                                    ADD_REPO = 'galaxy-gremlins'
                                    RM_REPO = 'galaxy'
                                } else if ( pkgPath[0].contains('community-x86_64') || pkgPath[0].contains('community-any') && pkgPath[1].contains('community-testing') ) {
                                    ADD_REPO = 'galaxy'
                                    RM_REPO = 'galaxy-gremlins'
                                }

                                if ( pkgPath[0].contains('multilib-staging') && pkgPath[1].contains('multilib-testing') ) {
                                    ADD_REPO = 'lib32-gremlins'
                                    RM_REPO = 'lib32-goblins'
                                } else if ( pkgPath[0].contains('multilib-testing') && pkgPath[1].contains('multilib-staging') ) {
                                    ADD_REPO = 'lib32-goblins'
                                    RM_REPO = 'lib32-gremlins'
                                }

                                if ( pkgPath[0].contains('multilib-testing') && pkgPath[1].contains('multilib-x86_64') ) {
                                    ADD_REPO = 'lib32'
                                    RM_REPO = 'lib32-gremlins'
                                } else if ( pkgPath[0].contains('multilib-x86_64') && pkgPath[1].contains('multilib-testing') ) {
                                    ADD_REPO = 'lib32-gremlins'
                                    RM_REPO = 'lib32'
                                }
                            }
                            PKG_TRUNK = buildInfo1[0] + '/trunk'
                        }

                        if ( pkgCount == 1 ) {
                            def pkgEntry = changedPkgStatus[0].split()
                            def pkgStatus = pkgEntry[0]
                            def srcPath = pkgEntry[1]
                            def buildInfo = srcPath.tokenize('/')

                            if ( srcPath.contains('community-staging') ) {
                                if ( pkgStatus == 'A' || pkgStatus == 'M' ) {
                                    IS_BUILD = 'true'
                                }
                                if ( pkgStatus == 'D' ) {
                                    IS_REMOVE = 'true'
                                }
                                ADD_REPO = 'galaxy-goblins'
                                RM_REPO = ADD_REPO
                            } else if ( srcPath.contains('community-testing') ) {
                                if ( pkgStatus == 'A' || pkgStatus == 'M' ) {
                                    IS_BUILD = 'true'
                                }
                                if ( pkgStatus == 'D' ) {
                                    IS_REMOVE = 'true'
                                }
                                ADD_REPO = 'galaxy-gremlins'
                                RM_REPO = ADD_REPO
                            } else if ( srcPath.contains('community-x86_64') || srcPath.contains('community-any') ) {
                                if ( pkgStatus == 'A' || pkgStatus == 'M' ) {
                                    IS_BUILD = 'true'
                                }
                                if ( pkgStatus == 'D' ) {
                                    IS_REMOVE = 'true'
                                }
                                ADD_REPO = 'galaxy'
                                RM_REPO = ADD_REPO
                            }
                            if ( srcPath.contains('multilib-staging') ) {
                                if ( pkgStatus == 'A' || pkgStatus == 'M' ) {
                                    IS_BUILD = 'true'
                                }
                                if ( pkgStatus == 'D' ) {
                                    IS_REMOVE = 'true'
                                }
                                ADD_REPO = 'lib32-goblins'
                                RM_REPO = ADD_REPO
                            } else if ( srcPath.contains('multilib-testing') ) {
                                if ( pkgStatus == 'A' || pkgStatus == 'M' ) {
                                    IS_BUILD = 'true'
                                }
                                if ( pkgStatus == 'D' ) {
                                    IS_REMOVE = 'true'
                                }
                                ADD_REPO = 'lib32-gremlins'
                                RM_REPO = ADD_REPO
                            } else if ( srcPath.contains('multilib-x86_64') ) {
                                if ( pkgStatus == 'A' || pkgStatus == 'M' ) {
                                    IS_BUILD = 'true'
                                }
                                if ( pkgStatus == 'D' ) {
                                    IS_REMOVE = 'true'
                                }
                                ADD_REPO = 'lib32'
                                RM_REPO = ADD_REPO
                            }
                            PKG_PATH = srcPath
                            PKG_TRUNK = buildInfo[0] + '/trunk'
                        }

                    }
                }
            }
        }
        stage('Build') {
            environment {
                BUILDBOT_GPGP = credentials('BUILDBOT_GPGP')
            }
            when {
                expression { return  IS_BUILD == 'true' }
            }
            steps {
                dir("${PKG_PATH}") {
                    sh "buildpkg -r ${ADD_REPO}"
                }
            }
            post {
                success {
                    dir("${PKG_PATH}") {
                        sh "deploypkg -a -d ${ADD_REPO} -s"
                    }
                }
            }
        }
        stage('Add') {
            when {
                expression { return  IS_ADD == 'true' }
            }
            steps {
                dir("${PKG_TRUNK}") {
                    sh "deploypkg -a -d ${ADD_REPO}"
                }
            }
        }
        stage('Remove') {
            when {
                expression { return  IS_REMOVE == 'true' }
            }
            steps {
                dir("${PKG_TRUNK}") {
                    sh "deploypkg -r -d ${RM_REPO}"
                }
            }
        }
    }
}
