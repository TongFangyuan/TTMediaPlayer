import os, sys


pod_lib_command = "pod lib lint --allow-warnings"
pod_register_command = "pod trunk register 573682532@qq.com 'tongfy' --description='Mac Pro' --verbose"
pod_push_command = "pod trunk push TTMediaPlayer.podspec --allow-warnings"


def pod_run():
    print("-------------waiting pod lib--------------------")
    os.system(pod_lib_command)
    print("-------------waiting pod register --------------------")
    os.system(pod_register_command)
    print("-------------waiting pod push --------------------")
    os.system(pod_push_command)


pod_run()


