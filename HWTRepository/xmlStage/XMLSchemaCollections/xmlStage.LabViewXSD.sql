CREATE XML SCHEMA COLLECTION
	xmlStage.LabViewXSD
AS N'<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
	<xsd:element name="root">
		<xsd:complexType>
			<xsd:sequence>
				<xsd:element name="header">
					<xsd:complexType>
						<xsd:sequence>
							<xsd:element name="Result_File" type="xsd:string"/>
							<xsd:element name="Start_Time" type="xsd:string"/>
							<xsd:element name="Finish_Time" type="xsd:string"/>
							<xsd:element name="Test_Duration" type="xsd:string"/>
							<xsd:element name="Project_Name" type="xsd:string"/>
							<xsd:element name="Firmware_Rev" type="xsd:string"/>
							<xsd:element name="Hardware_Rev" type="xsd:string"/>
							<xsd:element name="Part_SN" type="xsd:string"/>
							<xsd:element name="Operator_Name" type="xsd:string"/>
							<xsd:element name="Test_Station_ID" type="xsd:string"/>
							<xsd:element name="Test_Name" type="xsd:string"/>
							<xsd:element name="Test_Config_File" type="xsd:string"/>
							<xsd:element name="Test_Code_Path_Name" type="xsd:string"/>
							<xsd:element name="Test_Code_Rev" type="xsd:string"/>
							<xsd:element name="HWTSys_Code_Rev" type="xsd:string"/>
							<xsd:element name="Kdrive_Path" type="xsd:string"/>
							<xsd:element name="equipment" minOccurs="0">
								<xsd:complexType>
									<xsd:sequence>
										<xsd:element name="equipment_element" minOccurs="0" maxOccurs="unbounded">
											<xsd:complexType>
												<xsd:sequence>
													<xsd:element name="Description" type="xsd:string"/>
													<xsd:element name="Asset" type="xsd:string"/>
													<xsd:element name="Calibration_Due_Date" type="xsd:string"/>
													<xsd:element name="Cost_Center" type="xsd:unsignedInt"/>
												</xsd:sequence>
											</xsd:complexType>
										</xsd:element>
									</xsd:sequence>
								</xsd:complexType>
							</xsd:element>
							<xsd:element name="External_File_Info" type="xsd:string"/>
							<xsd:element name="options" minOccurs="0">
								<xsd:complexType>
									<xsd:sequence>
										<xsd:element name="option_element" minOccurs="0" maxOccurs="unbounded">
											<xsd:complexType>
												<xsd:sequence>
													<xsd:choice maxOccurs="unbounded">
														<xsd:element name="name" type="xsd:string"/>
														<xsd:element name="type" type="xsd:string"/>
														<xsd:element name="units" type="xsd:string"/>
														<xsd:element name="value" type="xsd:string"/>
													</xsd:choice>
												</xsd:sequence>
											</xsd:complexType>
										</xsd:element>
										<xsd:element name="AppConst_element" minOccurs="0" maxOccurs="unbounded">
											<xsd:complexType>
												<xsd:sequence>
													<xsd:choice maxOccurs="unbounded">
														<xsd:element name="name" type="xsd:string"/>
														<xsd:element name="type" type="xsd:string"/>
														<xsd:element name="units" type="xsd:string"/>
														<xsd:element name="value" type="xsd:string"/>
													</xsd:choice>
												</xsd:sequence>
											</xsd:complexType>
										</xsd:element>
									</xsd:sequence>
								</xsd:complexType>
							</xsd:element>
							<xsd:element name="Comments" type="xsd:string"/>
							<xsd:element name="LibraryInfo" minOccurs="0">
								<xsd:complexType>
									<xsd:sequence>
										<xsd:element name="file" minOccurs="0" maxOccurs="unbounded">
											<xsd:complexType>
												<xsd:attribute name="name" type="xsd:string" use="required"/>
												<xsd:attribute name="rev" type="xsd:string" use="required"/>
												<xsd:attribute name="status" type="xsd:string" use="required"/>
												<xsd:attribute name="HashCode" type="xsd:string" use="required"/>
											</xsd:complexType>
										</xsd:element>
									</xsd:sequence>
								</xsd:complexType>
							</xsd:element>
						</xsd:sequence>
						<xsd:attribute name="ID" type="xsd:int"/>
					</xsd:complexType>
				</xsd:element>
				<xsd:element name="vector" minOccurs="0" maxOccurs="unbounded">
					<xsd:complexType>
						<xsd:sequence>
							<xsd:element name="num" type="xsd:unsignedShort"/>
							<xsd:element name="Loop" type="xsd:unsignedShort" minOccurs="0"/>
							<xsd:element name="vector_element" minOccurs="0" maxOccurs="unbounded">
								<xsd:complexType>
									<xsd:sequence>
										<xsd:element name="name" type="xsd:string"/>
										<xsd:element name="type" type="xsd:string"/>
										<xsd:element name="units" type="xsd:string"/>
										<xsd:element name="value" type="xsd:string"/>
									</xsd:sequence>
								</xsd:complexType>
							</xsd:element>
							<xsd:element name="ReqID" type="xsd:string" minOccurs="0" maxOccurs="unbounded"/>
							<xsd:element name="result_element" minOccurs="0" maxOccurs="unbounded">
								<xsd:complexType>
									<xsd:sequence>
										<xsd:choice maxOccurs="unbounded">
											<xsd:element name="name" type="xsd:string"/>
											<xsd:element name="units" type="xsd:string"/>
											<xsd:element name="type" type="xsd:string"/>
											<xsd:element name="value" type="xsd:string" minOccurs="0" maxOccurs="unbounded"/>
										</xsd:choice>
									</xsd:sequence>
								</xsd:complexType>
							</xsd:element>
							<xsd:element name="error_element" minOccurs="0">
								<xsd:complexType>
									<xsd:sequence>
										<xsd:element name="test_error" minOccurs="0" maxOccurs="unbounded">
											<xsd:complexType>
												<xsd:simpleContent>
													<xsd:extension base="xsd:string">
														<xsd:attribute name="code" type="xsd:int" use="required"/>
													</xsd:extension>
												</xsd:simpleContent>
											</xsd:complexType>
										</xsd:element>
										<xsd:element name="data_error" minOccurs="0" maxOccurs="unbounded">
											<xsd:complexType>
												<xsd:simpleContent>
													<xsd:extension base="xsd:string">
														<xsd:attribute name="num" type="xsd:int" use="required"/>
													</xsd:extension>
												</xsd:simpleContent>
											</xsd:complexType>
										</xsd:element>
										<xsd:element name="input_param_error" minOccurs="0" maxOccurs="unbounded">
											<xsd:complexType>
												<xsd:simpleContent>
													<xsd:extension base="xsd:string">
														<xsd:attribute name="num" type="xsd:int" use="required"/>
													</xsd:extension>
												</xsd:simpleContent>
											</xsd:complexType>
										</xsd:element>
									</xsd:sequence>
								</xsd:complexType>
							</xsd:element>
							<xsd:element name="Timestamp">
								<xsd:complexType>
									<xsd:sequence>
										<xsd:element name="StartTime" type="xsd:string"/>
										<xsd:element name="EndTime" type="xsd:string"/>
									</xsd:sequence>
								</xsd:complexType>
							</xsd:element>
						</xsd:sequence>
					</xsd:complexType>
				</xsd:element>
			</xsd:sequence>
		</xsd:complexType>
	</xsd:element>
</xsd:schema>';