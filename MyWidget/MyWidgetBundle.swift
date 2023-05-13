//
// MyWidgetBundle.swift
// Copyright (c) 2022 MyWidgetExtension
//
// Created by Hamed Hosseini on 12/16/22

import SwiftUI
import WidgetKit

@main
struct MyWidgetBundle: WidgetBundle {
    var body: some Widget {
        SimpleWidget()
        BlurNameWidget()
        MyWidgetLiveActivity()
    }
}
